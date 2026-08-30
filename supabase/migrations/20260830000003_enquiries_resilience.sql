-- Migration: 20260830000003_enquiries_resilience.sql
-- Description: Makes enquiries table completely resilient across all categories, guest users, and custom provider IDs.

-- 1. Drop NOT NULL on customer_id & provider_id so guest enquiries and mock providers never fail
ALTER TABLE public.enquiries ALTER COLUMN customer_id DROP NOT NULL;
ALTER TABLE public.enquiries ALTER COLUMN provider_id DROP NOT NULL;

-- 2. Drop FK constraints that could reject demo/mock provider IDs or unauthenticated customers
ALTER TABLE public.enquiries DROP CONSTRAINT IF EXISTS enquiries_customer_id_fkey;
ALTER TABLE public.enquiries DROP CONSTRAINT IF EXISTS enquiries_provider_id_fkey;

-- 3. Ensure all metadata columns exist
ALTER TABLE public.enquiries
  ADD COLUMN IF NOT EXISTS customer_name   TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS customer_phone  TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS provider_name   TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS service_title   TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS preferred_date  TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS preferred_time  TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS message         TEXT DEFAULT '';

-- 4. Ensure RLS allows public/authenticated insert without rejection
ALTER TABLE public.enquiries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "enquiries_insert_policy" ON public.enquiries;
DROP POLICY IF EXISTS "allow_insert_enquiries" ON public.enquiries;
CREATE POLICY "enquiries_insert_policy"
  ON public.enquiries FOR INSERT
  TO public
  WITH CHECK (true);

DROP POLICY IF EXISTS "enquiries_select_policy" ON public.enquiries;
CREATE POLICY "enquiries_select_policy"
  ON public.enquiries FOR SELECT
  TO public
  USING (true);

DROP POLICY IF EXISTS "enquiries_admin_all" ON public.enquiries;
CREATE POLICY "enquiries_admin_all"
  ON public.enquiries FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- 5. Grant full permissions
GRANT ALL ON public.enquiries TO anon, authenticated, service_role;

-- 6. Reload schema cache
NOTIFY pgrst, 'reload schema';
