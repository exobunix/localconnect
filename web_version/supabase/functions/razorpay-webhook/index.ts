import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── Razorpay Webhook Handler ───────────────────────────────────────────────
// Verifies HMAC-SHA256 signature using Deno's built-in Web Crypto API
// RAZORPAY_WEBHOOK_SECRET must be set as an Edge Function secret (never in Flutter)

const RAZORPAY_WEBHOOK_SECRET = Deno.env.get("RAZORPAY_WEBHOOK_SECRET") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

// Tolerance for amount mismatch (in paise) — 0 means exact match required
const AMOUNT_TOLERANCE_PAISE = 0;

// ── HMAC-SHA256 using Deno built-in Web Crypto (no external imports) ───────
async function computeHmacSha256Hex(secret: string, message: string): Promise<string> {
  const encoder = new TextEncoder();
  const keyData = encoder.encode(secret);
  const messageData = encoder.encode(message);

  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    keyData,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign("HMAC", cryptoKey, messageData);
  const hashArray = Array.from(new Uint8Array(signature));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

serve(async (req: Request) => {
  // ── Only accept POST ───────────────────────────────────────────────────
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  // ── Validate secrets are configured ───────────────────────────────────
  if (!RAZORPAY_WEBHOOK_SECRET) {
    console.error("RAZORPAY_WEBHOOK_SECRET is not configured");
    return new Response(JSON.stringify({ error: "Webhook secret not configured" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    console.error("Supabase credentials not configured");
    return new Response(JSON.stringify({ error: "Database credentials not configured" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  // ── Read raw body for signature verification ───────────────────────────
  const rawBody = await req.text();

  // ── Verify HMAC-SHA256 signature ───────────────────────────────────────
  const razorpaySignature = req.headers.get("x-razorpay-signature");
  if (!razorpaySignature) {
    console.warn("Missing x-razorpay-signature header");
    return new Response(JSON.stringify({ error: "Missing signature header" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const expectedSignature = await computeHmacSha256Hex(RAZORPAY_WEBHOOK_SECRET, rawBody);

  if (expectedSignature !== razorpaySignature) {
    console.warn("Signature mismatch — possible fraud attempt", {
      received: razorpaySignature,
      expected: expectedSignature,
    });
    return new Response(JSON.stringify({ error: "Invalid signature" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  // ── Parse verified payload ─────────────────────────────────────────────
  let payload: Record<string, unknown>;
  try {
    payload = JSON.parse(rawBody);
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON payload" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const event = payload.event as string;
  const paymentEntity = (payload.payload as Record<string, unknown>)?.payment as Record<string, unknown>;
  const entity = paymentEntity?.entity as Record<string, unknown>;

  console.log(`Received Razorpay webhook event: ${event}`);

  // ── Initialize Supabase admin client (bypasses RLS) ────────────────────
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  // ── Route by event type ────────────────────────────────────────────────
  switch (event) {
    case "payment.captured":
    case "payment.authorized": {
      const result = await handlePaymentCaptured(supabase, entity, event);
      return result;
    }

    case "payment.failed": {
      const result = await handlePaymentFailed(supabase, entity);
      return result;
    }

    case "refund.created":
    case "refund.processed": {
      const result = await handleRefund(supabase, payload, event);
      return result;
    }

    case "subscription.charged": {
      const result = await handleSubscriptionCharged(supabase, payload);
      return result;
    }

    case "subscription.cancelled":
    case "subscription.expired": {
      const result = await handleSubscriptionStatusChange(supabase, payload, event);
      return result;
    }

    default:
      console.log(`Unhandled event type: ${event} — acknowledged`);
      return new Response(JSON.stringify({ status: "acknowledged", event }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
  }
});

// ── Helper: update orders table payment_status in real-time ──────────────
// Looks up the order linked to a razorpay_transaction and updates its
// payment_status so the Flutter app sees the change via Supabase Realtime.
async function updateOrderPaymentStatus(
  supabase: ReturnType<typeof createClient>,
  razorpayPaymentId: string,
  razorpayOrderId: string | null,
  newPaymentStatus: string // 'paid' | 'failed' | 'refunded'
): Promise<void> {
  // Strategy 1: match via razorpay_transactions.order_id (UUID FK to orders)
  const { data: txRow } = await supabase
    .from("razorpay_transactions")
    .select("order_id")
    .eq("razorpay_payment_id", razorpayPaymentId)
    .maybeSingle();

  if (txRow?.order_id) {
    const { error } = await supabase
      .from("orders")
      .update({
        payment_status: newPaymentStatus,
        razorpay_payment_id: razorpayPaymentId,
        updated_at: new Date().toISOString(),
      })
      .eq("id", txRow.order_id);

    if (error) {
      console.error(`Failed to update orders (by tx.order_id) to ${newPaymentStatus}:`, error.message);
    } else {
      console.log(`Order ${txRow.order_id} payment_status → ${newPaymentStatus}`);
    }
    return;
  }

  // Strategy 2: match via orders.razorpay_order_id column (set during checkout)
  if (razorpayOrderId) {
    const { error } = await supabase
      .from("orders")
      .update({
        payment_status: newPaymentStatus,
        razorpay_payment_id: razorpayPaymentId,
        updated_at: new Date().toISOString(),
      })
      .eq("razorpay_order_id", razorpayOrderId);

    if (error) {
      console.error(`Failed to update orders (by razorpay_order_id) to ${newPaymentStatus}:`, error.message);
    } else {
      console.log(`Order with razorpay_order_id=${razorpayOrderId} payment_status → ${newPaymentStatus}`);
    }
  }
}

// ── Handler: payment.captured / payment.authorized ────────────────────────
async function handlePaymentCaptured(
  supabase: ReturnType<typeof createClient>,
  entity: Record<string, unknown>,
  event: string
): Promise<Response> {
  const razorpayPaymentId = entity?.id as string;
  const razorpayOrderId = entity?.order_id as string;
  const amountPaise = entity?.amount as number; // Razorpay sends amount in paise
  const amountRupees = amountPaise / 100;
  const currency = (entity?.currency as string) ?? "INR";
  const status = event === "payment.captured" ? "success" : "authorized";

  if (!razorpayPaymentId) {
    return jsonResponse({ error: "Missing payment ID in payload" }, 400);
  }

  // ── Look up existing transaction by razorpay_payment_id ───────────────
  const { data: existingTx, error: fetchError } = await supabase
    .from("razorpay_transactions")
    .select("id, amount, status, razorpay_order_id")
    .eq("razorpay_payment_id", razorpayPaymentId)
    .maybeSingle();

  if (fetchError) {
    console.error("Error fetching transaction:", fetchError);
    return jsonResponse({ error: "Database error fetching transaction" }, 500);
  }

  if (existingTx) {
    // ── Validate amount matches what was recorded ──────────────────────
    const recordedAmount = parseFloat(existingTx.amount);
    const diff = Math.abs(recordedAmount - amountRupees);

    if (diff > AMOUNT_TOLERANCE_PAISE / 100) {
      console.error("FRAUD ALERT: Amount mismatch detected", {
        razorpayPaymentId,
        recordedAmount,
        webhookAmount: amountRupees,
        difference: diff,
      });

      // Mark transaction as fraud-suspected
      await supabase
        .from("razorpay_transactions")
        .update({
          status: "failed",
          webhook_verified: false,
          webhook_event: event,
          webhook_received_at: new Date().toISOString(),
          fraud_flag: true,
          fraud_reason: `Amount mismatch: recorded ₹${recordedAmount}, webhook ₹${amountRupees}`,
          updated_at: new Date().toISOString(),
        })
        .eq("id", existingTx.id);

      // Update order to failed on fraud detection
      await updateOrderPaymentStatus(supabase, razorpayPaymentId, razorpayOrderId ?? null, "failed");

      return jsonResponse({
        error: "Amount mismatch — transaction flagged",
        recorded: recordedAmount,
        received: amountRupees,
      }, 422);
    }

    // ── Amount valid — mark as webhook-verified ────────────────────────
    const { error: updateError } = await supabase
      .from("razorpay_transactions")
      .update({
        status: status,
        webhook_verified: true,
        webhook_event: event,
        webhook_received_at: new Date().toISOString(),
        fraud_flag: false,
        updated_at: new Date().toISOString(),
      })
      .eq("id", existingTx.id);

    if (updateError) {
      console.error("Error updating transaction:", updateError);
      return jsonResponse({ error: "Failed to update transaction" }, 500);
    }

    // ── Propagate to orders table in real-time ─────────────────────────
    await updateOrderPaymentStatus(supabase, razorpayPaymentId, razorpayOrderId ?? null, "paid");

    console.log(`Transaction ${existingTx.id} verified and marked ${status}`);
    return jsonResponse({ status: "success", transactionId: existingTx.id });

  } else {
    // ── No existing record — insert from webhook (e.g., direct capture) ─
    const { data: inserted, error: insertError } = await supabase
      .from("razorpay_transactions")
      .insert({
        razorpay_payment_id: razorpayPaymentId,
        razorpay_order_id: razorpayOrderId ?? null,
        amount: amountRupees,
        currency,
        payment_type: "one_time",
        status: "success",
        description: `Webhook-captured payment: ${event}`,
        webhook_verified: true,
        webhook_event: event,
        webhook_received_at: new Date().toISOString(),
        fraud_flag: false,
        metadata: { source: "webhook", raw_entity: entity },
      })
      .select("id")
      .single();

    if (insertError) {
      console.error("Error inserting webhook transaction:", insertError);
      return jsonResponse({ error: "Failed to insert transaction" }, 500);
    }

    // ── Propagate to orders table in real-time ─────────────────────────
    await updateOrderPaymentStatus(supabase, razorpayPaymentId, razorpayOrderId ?? null, "paid");

    console.log(`New transaction created from webhook: ${inserted.id}`);
    return jsonResponse({ status: "created", transactionId: inserted.id });
  }
}

// ── Handler: payment.failed ───────────────────────────────────────────────
async function handlePaymentFailed(
  supabase: ReturnType<typeof createClient>,
  entity: Record<string, unknown>
): Promise<Response> {
  const razorpayPaymentId = entity?.id as string;
  const razorpayOrderId = entity?.order_id as string;
  const errorDescription = (entity?.error_description as string) ?? "Payment failed";

  if (!razorpayPaymentId) {
    return jsonResponse({ error: "Missing payment ID" }, 400);
  }

  const { error } = await supabase
    .from("razorpay_transactions")
    .update({
      status: "failed",
      webhook_verified: true,
      webhook_event: "payment.failed",
      webhook_received_at: new Date().toISOString(),
      fraud_flag: false,
      metadata: { failure_reason: errorDescription },
      updated_at: new Date().toISOString(),
    })
    .eq("razorpay_payment_id", razorpayPaymentId);

  if (error) {
    console.error("Error updating failed payment:", error);
    return jsonResponse({ error: "Failed to update transaction" }, 500);
  }

  // ── Propagate to orders table in real-time ─────────────────────────────
  await updateOrderPaymentStatus(supabase, razorpayPaymentId, razorpayOrderId ?? null, "failed");

  console.log(`Payment ${razorpayPaymentId} marked as failed`);
  return jsonResponse({ status: "updated", event: "payment.failed" });
}

// ── Handler: refund.created / refund.processed ────────────────────────────
async function handleRefund(
  supabase: ReturnType<typeof createClient>,
  payload: Record<string, unknown>,
  event: string
): Promise<Response> {
  const refundPayload = (payload.payload as Record<string, unknown>)?.refund as Record<string, unknown>;
  const refundEntity = refundPayload?.entity as Record<string, unknown>;
  const razorpayPaymentId = refundEntity?.payment_id as string;

  if (!razorpayPaymentId) {
    return jsonResponse({ error: "Missing payment ID in refund payload" }, 400);
  }

  const { error } = await supabase
    .from("razorpay_transactions")
    .update({
      status: "refunded",
      webhook_verified: true,
      webhook_event: event,
      webhook_received_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq("razorpay_payment_id", razorpayPaymentId);

  if (error) {
    console.error("Error updating refund:", error);
    return jsonResponse({ error: "Failed to update refund status" }, 500);
  }

  // ── Propagate to orders table in real-time ─────────────────────────────
  await updateOrderPaymentStatus(supabase, razorpayPaymentId, null, "refunded");

  console.log(`Refund processed for payment ${razorpayPaymentId}`);
  return jsonResponse({ status: "refunded", event });
}

// ── Handler: subscription.charged ────────────────────────────────────────
async function handleSubscriptionCharged(
  supabase: ReturnType<typeof createClient>,
  payload: Record<string, unknown>
): Promise<Response> {
  const subPayload = (payload.payload as Record<string, unknown>)?.subscription as Record<string, unknown>;
  const subEntity = subPayload?.entity as Record<string, unknown>;
  const paymentPayload = (payload.payload as Record<string, unknown>)?.payment as Record<string, unknown>;
  const paymentEntity = paymentPayload?.entity as Record<string, unknown>;

  const razorpaySubscriptionId = subEntity?.id as string;
  const razorpayPaymentId = paymentEntity?.id as string;
  const amountPaise = paymentEntity?.amount as number;
  const amountRupees = amountPaise ? amountPaise / 100 : 0;

  if (!razorpaySubscriptionId) {
    return jsonResponse({ error: "Missing subscription ID" }, 400);
  }

  // Update provider_subscriptions table if razorpay_subscription_id column exists
  const { error: subError } = await supabase
    .from("provider_subscriptions")
    .update({
      status: "active",
      updated_at: new Date().toISOString(),
    })
    .eq("razorpay_subscription_id", razorpaySubscriptionId);

  if (subError) {
    console.warn("Could not update provider_subscriptions (column may not exist yet):", subError.message);
  }

  // Record the subscription payment transaction
  if (razorpayPaymentId) {
    const { error: txError } = await supabase
      .from("razorpay_transactions")
      .upsert({
        razorpay_payment_id: razorpayPaymentId,
        amount: amountRupees,
        currency: "INR",
        payment_type: "subscription",
        status: "success",
        description: `Subscription auto-charge: ${razorpaySubscriptionId}`,
        webhook_verified: true,
        webhook_event: "subscription.charged",
        webhook_received_at: new Date().toISOString(),
        fraud_flag: false,
        metadata: { razorpay_subscription_id: razorpaySubscriptionId },
      }, { onConflict: "razorpay_payment_id" });

    if (txError) {
      console.error("Error recording subscription charge:", txError);
    }
  }

  console.log(`Subscription ${razorpaySubscriptionId} charged successfully`);
  return jsonResponse({ status: "subscription_charged", subscriptionId: razorpaySubscriptionId });
}

// ── Handler: subscription.cancelled / subscription.expired ───────────────
async function handleSubscriptionStatusChange(
  supabase: ReturnType<typeof createClient>,
  payload: Record<string, unknown>,
  event: string
): Promise<Response> {
  const subPayload = (payload.payload as Record<string, unknown>)?.subscription as Record<string, unknown>;
  const subEntity = subPayload?.entity as Record<string, unknown>;
  const razorpaySubscriptionId = subEntity?.id as string;

  if (!razorpaySubscriptionId) {
    return jsonResponse({ error: "Missing subscription ID" }, 400);
  }

  const newStatus = event === "subscription.cancelled" ? "cancelled" : "expired";

  const { error } = await supabase
    .from("provider_subscriptions")
    .update({
      status: newStatus,
      updated_at: new Date().toISOString(),
    })
    .eq("razorpay_subscription_id", razorpaySubscriptionId);

  if (error) {
    console.warn(`Could not update subscription status to ${newStatus}:`, error.message);
  }

  console.log(`Subscription ${razorpaySubscriptionId} status changed to ${newStatus}`);
  return jsonResponse({ status: newStatus, subscriptionId: razorpaySubscriptionId });
}

// ── Utility: JSON response helper ─────────────────────────────────────────
function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
