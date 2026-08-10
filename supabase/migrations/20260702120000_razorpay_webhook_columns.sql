-- ── Razorpay Webhook Verification Columns ─────────────────────────────────
-- Adds columns required by the razorpay-webhook Edge Function:
--   webhook_verified   : TRUE when HMAC-SHA256 signature was confirmed by server
--   webhook_event      : The Razorpay event name (payment.captured, etc.)
--   webhook_received_at: Timestamp when webhook was processed
--   fraud_flag         : TRUE when amount mismatch or suspicious activity detected
--   fraud_reason       : Human-readable explanation of the fraud flag

ALTER TABLE public.razorpay_transactions
  ADD COLUMN IF NOT EXISTS webhook_verified BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS webhook_event TEXT,
  ADD COLUMN IF NOT EXISTS webhook_received_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS fraud_flag BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS fraud_reason TEXT;

-- ── Index for fraud monitoring queries ────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_razorpay_transactions_fraud_flag
  ON public.razorpay_transactions(fraud_flag)
  WHERE fraud_flag = TRUE;

CREATE INDEX IF NOT EXISTS idx_razorpay_transactions_webhook_verified
  ON public.razorpay_transactions(webhook_verified);

-- ── Service role policy (used by Edge Function with service role key) ──────
-- The Edge Function uses SUPABASE_SERVICE_ROLE_KEY which bypasses RLS.
-- This policy is a safety net for any future service-role-scoped access.
DROP POLICY IF EXISTS "service_role_manage_razorpay_transactions" ON public.razorpay_transactions;
CREATE POLICY "service_role_manage_razorpay_transactions"
ON public.razorpay_transactions
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- ── Admin fraud monitoring view ────────────────────────────────────────────
-- Allows admins to query fraud-flagged transactions easily
CREATE OR REPLACE VIEW public.razorpay_fraud_alerts AS
SELECT
  id,
  user_id,
  razorpay_payment_id,
  razorpay_order_id,
  amount,
  currency,
  payment_type,
  status,
  webhook_verified,
  webhook_event,
  webhook_received_at,
  fraud_flag,
  fraud_reason,
  created_at,
  updated_at
FROM public.razorpay_transactions
WHERE fraud_flag = TRUE
ORDER BY created_at DESC;

-- ── Grant admin access to fraud view ──────────────────────────────────────
-- Admins can query this view via the is_admin_user() function
GRANT SELECT ON public.razorpay_fraud_alerts TO authenticated;
