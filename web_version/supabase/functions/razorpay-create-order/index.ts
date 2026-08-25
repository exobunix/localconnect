import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── Razorpay Create Order Edge Function ───────────────────────────────────
// Creates a Razorpay order server-side so the order_id is generated securely.
// The Flutter app then passes this order_id to the Razorpay checkout options.
// This enables server-side payment signature verification.

const RAZORPAY_KEY_ID = Deno.env.get("RAZORPAY_KEY_ID") ?? "";
const RAZORPAY_KEY_SECRET = Deno.env.get("RAZORPAY_KEY_SECRET") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

// Restrict CORS to known app origins only
const ALLOWED_ORIGINS = [
  "https://localconne6282.builtwithrocket.new",
  "https://localconnect-x5pi441-prod.rocketpreview.app",
];

function getCorsHeaders(origin: string | null): Record<string, string> {
  const allowedOrigin = origin && ALLOWED_ORIGINS.includes(origin)
    ? origin
    : ALLOWED_ORIGINS[0];
  return {
    "Access-Control-Allow-Origin": allowedOrigin,
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
  };
}

serve(async (req: Request) => {
  const origin = req.headers.get("origin");
  const corsHeaders = getCorsHeaders(origin);

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // ── Validate secrets ───────────────────────────────────────────────────
  if (!RAZORPAY_KEY_ID || !RAZORPAY_KEY_SECRET) {
    console.error("Razorpay credentials not configured");
    return new Response(JSON.stringify({ error: "Razorpay credentials not configured" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // ── Authenticate caller via Supabase JWT ───────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing Authorization header" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false },
  });

  const token = authHeader.replace("Bearer ", "");
  const { data: { user }, error: authError } = await supabase.auth.getUser(token);

  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // ── Parse request body ─────────────────────────────────────────────────
  let body: {
    amount: number;       // Amount in rupees (will be converted to paise)
    currency?: string;
    receipt?: string;
    notes?: Record<string, string>;
    payment_type?: string;
    description?: string;
    order_id?: string;
    provider_id?: string;
    plan_id?: string;
  };

  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON body" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  if (!body.amount || body.amount <= 0) {
    return new Response(JSON.stringify({ error: "Invalid amount" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  // ── Amount validation: max ₹5,00,000 per transaction ──────────────────
  if (body.amount > 500000) {
    return new Response(JSON.stringify({ error: "Amount exceeds maximum allowed limit" }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const amountPaise = Math.round(body.amount * 100); // Convert rupees → paise
  const currency = body.currency ?? "INR";
  const receipt = body.receipt ?? `rcpt_${user.id.slice(0, 8)}_${Date.now()}`;

  // ── Create Razorpay order via REST API ─────────────────────────────────
  const credentials = btoa(`${RAZORPAY_KEY_ID}:${RAZORPAY_KEY_SECRET}`);

  const razorpayResponse = await fetch("https://api.razorpay.com/v1/orders", {
    method: "POST",
    headers: {
      "Authorization": `Basic ${credentials}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      amount: amountPaise,
      currency,
      receipt,
      notes: body.notes ?? {},
    }),
  });

  if (!razorpayResponse.ok) {
    const errText = await razorpayResponse.text();
    console.error("Razorpay order creation failed:", errText);
    return new Response(JSON.stringify({ error: "Failed to create Razorpay order" }), {
      status: razorpayResponse.status,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  const razorpayOrder = await razorpayResponse.json() as {
    id: string;
    amount: number;
    currency: string;
    receipt: string;
    status: string;
  };

  // ── Pre-record a pending transaction in Supabase ───────────────────────
  // This creates the DB row before checkout opens so webhook can match it.
  const { data: txRecord, error: txError } = await supabase
    .from("razorpay_transactions")
    .insert({
      user_id: user.id,
      razorpay_order_id: razorpayOrder.id,
      amount: body.amount,
      currency,
      payment_type: body.payment_type ?? "one_time",
      status: "pending",
      description: body.description ?? receipt,
      order_id: body.order_id ?? null,
      provider_id: body.provider_id ?? null,
      plan_id: body.plan_id ?? null,
      metadata: body.notes ?? {},
      webhook_verified: false,
      fraud_flag: false,
    })
    .select("id")
    .single();

  if (txError) {
    console.error("Failed to pre-record transaction:", txError);
    // Non-fatal — still return the order so checkout can proceed
  }

  console.log(`Created Razorpay order ${razorpayOrder.id} for user ${user.id}`);

  return new Response(
    JSON.stringify({
      razorpay_order_id: razorpayOrder.id,
      amount: razorpayOrder.amount,
      currency: razorpayOrder.currency,
      receipt: razorpayOrder.receipt,
      transaction_id: txRecord?.id ?? null,
    }),
    {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    }
  );
});
