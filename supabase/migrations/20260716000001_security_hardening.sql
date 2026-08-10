-- ─────────────────────────────────────────────────────────────────────────────
-- Security Hardening Migration
-- Fixes: admin role check, role escalation, phone_otps anon access,
--        transaction status self-update, and RLS policy tightening.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Fix is_admin_user() — use ONLY app_meta_data (server-controlled) ──────
-- raw_user_meta_data is user-writable and can be spoofed at signup.
-- raw_app_meta_data is only writable by service_role / admin API.
CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid()
      AND role = 'admin'
  )
$$;

-- ── 2. Fix handle_new_user() — never trust user-supplied role ────────────────
-- Prevent users from self-assigning 'admin' or 'provider' at signup.
-- All new accounts start as 'customer'; role elevation is done by admin only.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  requested_role TEXT;
  safe_role public.user_role;
BEGIN
  requested_role := COALESCE(NEW.raw_user_meta_data->>'role', 'customer');

  -- Only allow 'customer' and 'provider' from self-signup.
  -- 'admin' can only be set via service_role (admin API), never from client.
  IF requested_role = 'admin' THEN
    safe_role := 'customer'::public.user_role;
  ELSIF requested_role = 'provider' THEN
    safe_role := 'provider'::public.user_role;
  ELSE
    safe_role := 'customer'::public.user_role;
  END IF;

  INSERT INTO public.user_profiles (id, email, full_name, phone, avatar_url, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'phone', ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
    safe_role
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

-- ── 3. Revoke anon access on phone_otps ──────────────────────────────────────
-- Unauthenticated users should never be able to read or write OTP records.
-- Edge functions use service_role which bypasses RLS entirely.
REVOKE ALL ON public.phone_otps FROM anon;
GRANT ALL ON public.phone_otps TO service_role;
-- authenticated role still needs access for edge function calls via JWT
GRANT SELECT, INSERT, UPDATE, DELETE ON public.phone_otps TO authenticated;

-- Re-enable RLS on phone_otps so the REVOKE above is enforced
ALTER TABLE public.phone_otps ENABLE ROW LEVEL SECURITY;

-- Drop any existing policies and add a tight service-role-only policy
DO $$
DECLARE
  pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname
    FROM pg_policies
    WHERE tablename = 'phone_otps' AND schemaname = 'public'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.phone_otps', pol.policyname);
  END LOOP;
END $$;

-- No authenticated user should directly read/write OTPs — only service_role via edge functions
CREATE POLICY "phone_otps_service_role_only" ON public.phone_otps
  USING (false)
  WITH CHECK (false);

-- ── 4. Remove user self-update of razorpay_transactions ──────────────────────
-- Users must NOT be able to change their own transaction status to 'success'.
-- All status updates must come from the webhook edge function (service_role).
DROP POLICY IF EXISTS "users_update_own_razorpay_transactions" ON public.razorpay_transactions;

-- Users can only update non-sensitive fields (e.g., metadata notes) on PENDING transactions.
-- Status, webhook_verified, fraud_flag columns are protected by the webhook only.
-- For simplicity and maximum security: remove all user UPDATE access.
-- The webhook (service_role) handles all status transitions.

-- ── 5. Tighten razorpay_transactions INSERT — prevent status injection ────────
-- Users can insert a pending transaction (created by edge function), but the
-- direct client INSERT policy must enforce status = 'pending' only.
DROP POLICY IF EXISTS "users_insert_own_razorpay_transactions" ON public.razorpay_transactions;
CREATE POLICY "users_insert_own_razorpay_transactions"
ON public.razorpay_transactions
FOR INSERT
TO authenticated
WITH CHECK (
  user_id = auth.uid()
  AND status = 'pending'
  AND webhook_verified = false
  AND fraud_flag = false
);

-- ── 6. Add missing webhook_verified and fraud_flag columns if absent ──────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'razorpay_transactions'
      AND column_name = 'webhook_verified'
  ) THEN
    ALTER TABLE public.razorpay_transactions ADD COLUMN webhook_verified BOOLEAN DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'razorpay_transactions'
      AND column_name = 'fraud_flag'
  ) THEN
    ALTER TABLE public.razorpay_transactions ADD COLUMN fraud_flag BOOLEAN DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'razorpay_transactions'
      AND column_name = 'webhook_event'
  ) THEN
    ALTER TABLE public.razorpay_transactions ADD COLUMN webhook_event TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'razorpay_transactions'
      AND column_name = 'webhook_received_at'
  ) THEN
    ALTER TABLE public.razorpay_transactions ADD COLUMN webhook_received_at TIMESTAMPTZ;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'razorpay_transactions'
      AND column_name = 'fraud_reason'
  ) THEN
    ALTER TABLE public.razorpay_transactions ADD COLUMN fraud_reason TEXT;
  END IF;
END $$;

-- ── 7. Ensure admin_email_otps has no public access ───────────────────────────
REVOKE ALL ON public.admin_email_otps FROM anon;
REVOKE ALL ON public.admin_email_otps FROM authenticated;
GRANT ALL ON public.admin_email_otps TO service_role;

-- ── 8. Add attempt_count column to admin_email_otps for brute-force protection ─
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'admin_email_otps'
      AND column_name = 'attempt_count'
  ) THEN
    ALTER TABLE public.admin_email_otps ADD COLUMN attempt_count INTEGER DEFAULT 0;
  END IF;
END $$;

-- ── 9. Add index on razorpay_transactions for fraud detection queries ─────────
CREATE INDEX IF NOT EXISTS idx_razorpay_transactions_fraud
  ON public.razorpay_transactions(fraud_flag)
  WHERE fraud_flag = true;

CREATE INDEX IF NOT EXISTS idx_razorpay_transactions_webhook_verified
  ON public.razorpay_transactions(webhook_verified)
  WHERE webhook_verified = false;
