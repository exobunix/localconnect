-- Migration: 20260830000004_enquiries_reply_and_full_access.sql
-- Description: Adds provider_reply, replied_at, and full multi-role access for customer, provider, and admin enquiry management.

-- 1. Ensure all enquiry columns including replies exist
ALTER TABLE public.enquiries
  ADD COLUMN IF NOT EXISTS customer_name   TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS customer_phone  TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS provider_name   TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS provider_reply  TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS replied_at      TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS service_title   TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS preferred_date  TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS preferred_time  TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS message         TEXT DEFAULT '';

-- 2. Drop any blocking NOT NULL or FK constraints
ALTER TABLE public.enquiries ALTER COLUMN customer_id DROP NOT NULL;
ALTER TABLE public.enquiries ALTER COLUMN provider_id DROP NOT NULL;
ALTER TABLE public.enquiries DROP CONSTRAINT IF EXISTS enquiries_customer_id_fkey;
ALTER TABLE public.enquiries DROP CONSTRAINT IF EXISTS enquiries_provider_id_fkey;

-- 3. RLS Policies for Customer, Provider, and Admin
ALTER TABLE public.enquiries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "enquiries_insert_policy" ON public.enquiries;
CREATE POLICY "enquiries_insert_policy"
  ON public.enquiries FOR INSERT
  TO public
  WITH CHECK (true);

DROP POLICY IF EXISTS "enquiries_select_policy" ON public.enquiries;
CREATE POLICY "enquiries_select_policy"
  ON public.enquiries FOR SELECT
  TO public
  USING (true);

DROP POLICY IF EXISTS "enquiries_update_policy" ON public.enquiries;
CREATE POLICY "enquiries_update_policy"
  ON public.enquiries FOR UPDATE
  TO public
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "enquiries_delete_policy" ON public.enquiries;
CREATE POLICY "enquiries_delete_policy"
  ON public.enquiries FOR DELETE
  TO public
  USING (true);

-- 4. Grant full access to all roles
GRANT ALL ON public.enquiries TO anon, authenticated, service_role;

-- 5. Force reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
