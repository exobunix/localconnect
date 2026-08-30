-- Migration: 20260830000002_fix_enquiries_rls_auth_users_permission.sql
-- Description:
--   Fixes 403 "permission denied for table users" when inserting into enquiries.
--
--   Root cause: The admin_all_enquiries and admin_all_quotations RLS policies
--   query `auth.users` directly, which the `authenticated` role cannot access.
--
--   Fix: Replace direct `auth.users` queries with public.is_admin_user()
--   which is a SECURITY DEFINER function that can safely access auth.users.

-- ─── enquiries ────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "admin_all_enquiries" ON public.enquiries;

CREATE POLICY "admin_all_enquiries"
  ON public.enquiries FOR ALL TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- Ensure INSERT is allowed for customers (the customer insert policy)
DROP POLICY IF EXISTS "customers_manage_own_enquiries" ON public.enquiries;

CREATE POLICY "customers_manage_own_enquiries"
  ON public.enquiries FOR ALL TO authenticated
  USING (customer_id = auth.uid())
  WITH CHECK (customer_id = auth.uid());

-- ─── quotations ──────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "admin_all_quotations" ON public.quotations;

CREATE POLICY "admin_all_quotations"
  ON public.quotations FOR ALL TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- ─── GRANT INSERT on enquiries to authenticated ───────────────────────────────
GRANT SELECT, INSERT, UPDATE ON public.enquiries TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.quotations TO authenticated;

-- ─── Force PostgREST schema cache reload ─────────────────────────────────────
NOTIFY pgrst, 'reload schema';
