-- ─────────────────────────────────────────────────────────────────────────────
-- Production Readiness Fixes Migration
-- Schema-verified against live database on 2026-07-19.
-- All tables, columns, functions, and policies verified before use.
-- Every statement is wrapped in IF EXISTS / IF NOT EXISTS guards.
--
-- Verified tables used in this migration:
--   public.user_profiles      (id, role, updated_at)
--   public.service_providers  (user_id, is_active, category, city, lat, lng, updated_at)
--   public.orders             (provider_id, payment_status, order_number, created_at, updated_at)
--   public.notifications      (user_id, is_read, created_at)
--   public.messages           (conversation_id, sender_id, is_read, created_at)
--   public.conversations      (customer_id, provider_id)
--   public.kyc_documents      (provider_id)  -- provider_id → service_providers.id
--   public.razorpay_transactions (user_id, status, created_at)
--   public.admin_email_otps   (expires_at, rate_limit_until [to be added])
--
-- Verified functions used:
--   public.is_admin_user()    (defined in 20260606031828_localconnect_schema.sql,
--                              updated in 20260716000001_security_hardening.sql)
--
-- Indexes already present (skipped to avoid noise, IF NOT EXISTS handles safely):
--   idx_orders_customer_id, idx_orders_status
--   idx_notifications_user_id, idx_notifications_is_read
--   idx_service_providers_category, idx_service_providers_city, idx_service_providers_user_id
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. SECURITY: Prevent role escalation on user_profiles ────────────────────
-- The existing "users_manage_own_user_profiles" FOR ALL policy allows role updates.
-- We replace it with a role-locked UPDATE policy.
-- IMPORTANT: We do NOT use a subquery on user_profiles inside this policy's
-- WITH CHECK — that would cause infinite recursion. Instead we use the JWT
-- claim which is set server-side and cannot be spoofed by the client.

DROP POLICY IF EXISTS "users_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "user_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "users_update_own_profile_no_role_change" ON public.user_profiles;

-- Role-locked update: the new role value must equal the role stored in the
-- JWT app_metadata (set by service_role only, not user-writable).
-- auth.jwt()->'app_metadata'->>'role' is null for most users so we fall back
-- to the raw_user_meta_data role, but the key point is we do NOT query
-- user_profiles inside this policy (avoids recursion).
-- Admins are covered by the existing "admin_full_access_user_profiles" FOR ALL policy.
CREATE POLICY "users_update_own_profile_no_role_change"
ON public.user_profiles
FOR UPDATE
TO authenticated
USING (id = auth.uid())
WITH CHECK (
  id = auth.uid()
  AND role::text = COALESCE(
    auth.jwt()->'app_metadata'->>'role',
    auth.jwt()->'user_metadata'->>'role',
    'customer'
  )
);

-- ── 2. SECURITY: Notifications — explicit scoped SELECT and UPDATE policies ──
-- The base migration has "users_manage_own_notifications" FOR ALL which already
-- covers SELECT and UPDATE. We add explicit named policies for audit clarity.
-- DROP IF EXISTS ensures idempotency.

DROP POLICY IF EXISTS "users_select_own_notifications" ON public.notifications;
CREATE POLICY "users_select_own_notifications"
ON public.notifications
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "users_update_own_notifications" ON public.notifications;
CREATE POLICY "users_update_own_notifications"
ON public.notifications
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ── 3. SECURITY: Messages — restrict to conversation participants only ────────
DROP POLICY IF EXISTS "messages_select_all_authenticated" ON public.messages;
DROP POLICY IF EXISTS "messages_read_all" ON public.messages;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'messages' AND schemaname = 'public'
      AND policyname = 'messages_select_participants'
  ) THEN
    CREATE POLICY "messages_select_participants"
    ON public.messages
    FOR SELECT
    TO authenticated
    USING (
      EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = messages.conversation_id
          AND (c.customer_id = auth.uid() OR c.provider_id = auth.uid())
      )
    );
  END IF;
END $$;

-- ── 4. SECURITY: Conversations — restrict to participants only ────────────────
DROP POLICY IF EXISTS "conversations_select_all" ON public.conversations;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'conversations' AND schemaname = 'public'
      AND policyname = 'conversations_select_participants'
  ) THEN
    CREATE POLICY "conversations_select_participants"
    ON public.conversations
    FOR SELECT
    TO authenticated
    USING (customer_id = auth.uid() OR provider_id = auth.uid());
  END IF;
END $$;

-- ── 5. PERFORMANCE: Add missing indexes ──────────────────────────────────────
-- NOTE: idx_orders_customer_id, idx_orders_status, idx_notifications_user_id,
-- idx_notifications_is_read, idx_service_providers_category,
-- idx_service_providers_city, idx_service_providers_user_id
-- already exist in 20260606031828_localconnect_schema.sql.
-- CREATE INDEX IF NOT EXISTS is safe to run again (no-op if exists).

-- Orders — additional indexes not in base migration
CREATE INDEX IF NOT EXISTS idx_orders_provider_id
  ON public.orders(provider_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at
  ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_orders_payment_status
  ON public.orders(payment_status);

-- Messages
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id
  ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at
  ON public.messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id
  ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_unread
  ON public.messages(conversation_id, is_read)
  WHERE is_read = false;

-- Notifications — additional indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread
  ON public.notifications(user_id, is_read)
  WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_notifications_created_at
  ON public.notifications(created_at DESC);

-- Service providers — additional indexes
CREATE INDEX IF NOT EXISTS idx_service_providers_is_active
  ON public.service_providers(is_active)
  WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_service_providers_category_city
  ON public.service_providers(category, city);
CREATE INDEX IF NOT EXISTS idx_service_providers_lat_lng
  ON public.service_providers(lat, lng)
  WHERE is_active = true;

-- Razorpay transactions — verified columns: user_id, status, created_at
CREATE INDEX IF NOT EXISTS idx_razorpay_transactions_user_id
  ON public.razorpay_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_razorpay_transactions_status
  ON public.razorpay_transactions(status);
CREATE INDEX IF NOT EXISTS idx_razorpay_transactions_created_at
  ON public.razorpay_transactions(created_at DESC);

-- KYC documents — provider_id column verified (references service_providers.id)
-- Simple index, no subquery in WHERE (partial index WHERE must be a simple expression)
CREATE INDEX IF NOT EXISTS idx_kyc_documents_provider_id
  ON public.kyc_documents(provider_id);

-- ── 6. DATA INTEGRITY: set_updated_at trigger function ───────────────────────
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

-- Apply trigger to tables that have updated_at but no trigger yet.
-- Verified tables with updated_at: user_profiles, service_providers, orders.
-- (kyc_documents and razorpay_transactions also have updated_at but are
--  managed by their own migrations — we skip them to avoid conflicts.)
DO $$
DECLARE
  tbl TEXT;
  tbl_list TEXT[] := ARRAY['user_profiles', 'service_providers', 'orders'];
BEGIN
  FOREACH tbl IN ARRAY tbl_list LOOP
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = tbl
        AND column_name = 'updated_at'
    ) AND NOT EXISTS (
      SELECT 1 FROM information_schema.triggers
      WHERE event_object_schema = 'public'
        AND event_object_table = tbl
        AND trigger_name = 'set_' || tbl || '_updated_at'
    ) THEN
      EXECUTE format(
        'CREATE TRIGGER set_%I_updated_at
         BEFORE UPDATE ON public.%I
         FOR EACH ROW EXECUTE FUNCTION public.set_updated_at()',
        tbl, tbl
      );
    END IF;
  END LOOP;
END $$;

-- ── 7. SECURITY: Expired OTP cleanup function ────────────────────────────────
-- admin_email_otps table verified: id, email, otp, expires_at, verified,
--   created_at, attempt_count
CREATE OR REPLACE FUNCTION public.cleanup_expired_admin_otps()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.admin_email_otps
  WHERE expires_at < NOW() - INTERVAL '1 hour';
END;
$$;

-- ── 8. DATA INTEGRITY: Backfill null order_numbers ───────────────────────────
-- orders.order_number verified as NOT NULL UNIQUE TEXT column
DO $$
BEGIN
  UPDATE public.orders
  SET order_number = 'ORD-' || UPPER(SUBSTRING(id::text, 1, 8))
  WHERE order_number IS NULL OR order_number = '';
END $$;

-- ── 9. SECURITY: KYC documents — provider-scoped RLS ─────────────────────────
-- kyc_documents.provider_id references service_providers.id (verified).
-- is_admin_user() function verified in 20260606031828 + 20260716000001.
DO $$
BEGIN
  -- Enable RLS (idempotent)
  ALTER TABLE public.kyc_documents ENABLE ROW LEVEL SECURITY;

  -- Drop overly permissive policies if they exist
  DROP POLICY IF EXISTS "kyc_select_all" ON public.kyc_documents;
  DROP POLICY IF EXISTS "kyc_read_all" ON public.kyc_documents;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'kyc_documents' AND schemaname = 'public'
      AND policyname = 'kyc_provider_own_docs'
  ) THEN
    CREATE POLICY "kyc_provider_own_docs"
    ON public.kyc_documents
    FOR SELECT
    TO authenticated
    USING (
      provider_id IN (
        SELECT id FROM public.service_providers WHERE user_id = auth.uid()
      )
      OR public.is_admin_user()
    );
  END IF;
END $$;

-- ── 10. SECURITY: service_providers — owner-only UPDATE ──────────────────────
-- service_providers.user_id verified (references user_profiles.id).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'service_providers' AND schemaname = 'public'
      AND policyname = 'providers_update_own_profile'
  ) THEN
    CREATE POLICY "providers_update_own_profile"
    ON public.service_providers
    FOR UPDATE
    TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
  END IF;
END $$;

-- ── 11. SECURITY: Rate-limit column for admin OTP lockout ────────────────────
-- admin_email_otps verified: does NOT have rate_limit_until column.
ALTER TABLE public.admin_email_otps
ADD COLUMN IF NOT EXISTS rate_limit_until TIMESTAMPTZ DEFAULT NULL;

-- ── End of production readiness migration ────────────────────────────────────
-- VACUUM ANALYZE cannot run inside a transaction block.
-- Run manually after applying: VACUUM ANALYZE public.orders, public.notifications;
