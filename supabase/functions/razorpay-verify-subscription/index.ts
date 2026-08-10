import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── Razorpay Subscription Verify Edge Function ────────────────────────────
// Verifies Razorpay payment signature server-side and activates subscription.
// Called after successful Razorpay checkout from Flutter app.

const RAZORPAY_KEY_ID = Deno.env.get("RAZORPAY_KEY_ID") ?? "";
const RAZORPAY_KEY_SECRET = Deno.env.get("RAZORPAY_KEY_SECRET") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const ALLOWED_ORIGINS = [
  "https://localconne6282.builtwithrocket.new",
  "https://localconnect-x5pi441-prod.rocketpreview.app",
];

function getCorsHeaders(origin: string | null): Record<string, string> {
  const allowedOrigin = origin && ALLOWED_ORIGINS.includes(origin)
    ? origin : ALLOWED_ORIGINS[0];
  return {
    "Access-Control-Allow-Origin": allowedOrigin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

async function computeHmacSha256Hex(secret: string, message: string): Promise<string> {
  const encoder = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    "raw", encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign"]
  );
  const signature = await crypto.subtle.sign("HMAC", cryptoKey, encoder.encode(message));
  return Array.from(new Uint8Array(signature)).map(b => b.toString(16).padStart(2, "0")).join("");
}

function jsonResponse(data: unknown, status = 200, corsHeaders: Record<string, string> = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

serve(async (req: Request) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "Method not allowed" }, 405, corsHeaders);

  // Authenticate caller
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return jsonResponse({ error: "Missing Authorization" }, 401, corsHeaders);

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const token = authHeader.replace("Bearer ", "");
  const { data: { user }, error: authError } = await supabase.auth.getUser(token);
  if (authError || !user) return jsonResponse({ error: "Unauthorized" }, 401, corsHeaders);

  let body: {
    razorpay_payment_id: string;
    razorpay_order_id: string;
    razorpay_signature: string;
    provider_id: string;
    plan_id: string;
    amount: number;
    is_renewal?: boolean;
    auto_renew?: boolean;
  };

  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, 400, corsHeaders);
  }

  const { razorpay_payment_id, razorpay_order_id, razorpay_signature, provider_id, plan_id, amount } = body;

  if (!razorpay_payment_id || !razorpay_order_id || !razorpay_signature || !provider_id || !plan_id) {
    return jsonResponse({ error: "Missing required fields" }, 400, corsHeaders);
  }

  // ── Verify Razorpay signature ──────────────────────────────────────────
  const signaturePayload = `${razorpay_order_id}|${razorpay_payment_id}`;
  const expectedSignature = await computeHmacSha256Hex(RAZORPAY_KEY_SECRET, signaturePayload);

  if (expectedSignature !== razorpay_signature) {
    console.error("Signature mismatch — possible fraud", { razorpay_payment_id });
    // Log fraud attempt
    await supabase.from("subscription_payment_audit").insert({
      provider_id,
      plan_id,
      event_type: "payment_fraud_attempt",
      razorpay_payment_id,
      razorpay_order_id,
      amount,
      status: "failed",
      metadata: { reason: "signature_mismatch", user_id: user.id },
    });
    return jsonResponse({ error: "Invalid payment signature" }, 401, corsHeaders);
  }

  // ── Fetch plan details ─────────────────────────────────────────────────
  const { data: plan, error: planError } = await supabase
    .from("subscription_plans")
    .select("*")
    .eq("id", plan_id)
    .single();

  if (planError || !plan) {
    return jsonResponse({ error: "Plan not found" }, 404, corsHeaders);
  }

  const durationDays = plan.duration_days ?? 30;
  const now = new Date();
  const endDate = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);

  // ── Expire existing active subscriptions ──────────────────────────────
  await supabase
    .from("provider_subscriptions")
    .update({ status: "expired", updated_at: now.toISOString() })
    .eq("provider_id", provider_id)
    .eq("status", "active");

  // ── Create new active subscription ────────────────────────────────────
  const { data: newSub, error: subError } = await supabase
    .from("provider_subscriptions")
    .insert({
      provider_id,
      plan_id,
      status: "active",
      is_trial: false,
      start_date: now.toISOString(),
      end_date: endDate.toISOString(),
      started_at: now.toISOString(),
      expires_at: endDate.toISOString(),
      auto_renew: body.auto_renew ?? false,
      payment_ref: razorpay_payment_id,
      razorpay_payment_id,
      razorpay_order_id,
      updated_at: now.toISOString(),
    })
    .select()
    .single();

  if (subError) {
    console.error("Failed to create subscription:", subError);
    return jsonResponse({ error: "Failed to activate subscription" }, 500, corsHeaders);
  }

  // ── Record billing history ─────────────────────────────────────────────
  await supabase.from("subscription_billing_history").insert({
    provider_id,
    plan_id,
    subscription_id: newSub.id,
    amount,
    payment_ref: razorpay_payment_id,
    payment_method: "Razorpay",
    status: "paid",
    description: `${body.is_renewal ? "Renewal" : "New subscription"} — ${plan.name} plan`,
  });

  // ── Log payment audit ──────────────────────────────────────────────────
  await supabase.from("subscription_payment_audit").insert({
    provider_id,
    subscription_id: newSub.id,
    plan_id,
    event_type: "subscription_activated",
    razorpay_payment_id,
    razorpay_order_id,
    amount,
    currency: "INR",
    status: "success",
    metadata: {
      plan_name: plan.name,
      duration_days: durationDays,
      is_renewal: body.is_renewal ?? false,
      verified_server_side: true,
    },
  });

  // ── Update razorpay_transactions record ───────────────────────────────
  await supabase
    .from("razorpay_transactions")
    .update({
      status: "success",
      webhook_verified: true,
      razorpay_payment_id,
      razorpay_signature,
    })
    .eq("razorpay_order_id", razorpay_order_id);

  // ── Send in-app notification to provider ──────────────────────────────
  const { data: providerRow } = await supabase
    .from("service_providers")
    .select("user_id, business_name")
    .eq("id", provider_id)
    .single();

  if (providerRow?.user_id) {
    await supabase.from("notifications").insert({
      user_id: providerRow.user_id,
      title: "🎉 Subscription Activated!",
      body: `Your ${plan.name} plan is now active for ${durationDays} days. Welcome to LocalConnect Pro!`,
      type: "subscription",
      metadata: { subscription_id: newSub.id, plan_name: plan.name },
    }).catch(() => {});
  }

  console.log(`Subscription activated: provider=${provider_id} plan=${plan.name} sub=${newSub.id}`);

  return jsonResponse({
    success: true,
    subscription_id: newSub.id,
    plan_name: plan.name,
    start_date: now.toISOString(),
    end_date: endDate.toISOString(),
    duration_days: durationDays,
  }, 200, corsHeaders);
});
