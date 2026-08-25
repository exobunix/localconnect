-- phone_otps table: ensure it exists with correct schema, no blocking RLS policies.
-- This migration is idempotent and safe to run multiple times.

-- 1. Create table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.phone_otps (
  id         uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  phone      text        NOT NULL,
  otp        text        NOT NULL,
  expires_at timestamptz NOT NULL,
  verified   boolean     DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- 2. Ensure unique index on phone (required for DELETE+INSERT safety)
CREATE UNIQUE INDEX IF NOT EXISTS phone_otps_phone_idx ON public.phone_otps (phone);

-- 3. Disable RLS entirely — all access is via edge functions using the service role key.
--    The service role key bypasses RLS when RLS is disabled, so no policies are needed.
ALTER TABLE public.phone_otps DISABLE ROW LEVEL SECURITY;

-- 4. Drop any blocking policies that may have been created by earlier migrations
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

-- 5. Grant full access to service_role and authenticated roles
GRANT ALL ON public.phone_otps TO service_role;
GRANT ALL ON public.phone_otps TO authenticated;
GRANT ALL ON public.phone_otps TO anon;

-- 6. Cleanup function for expired OTPs
CREATE OR REPLACE FUNCTION public.cleanup_expired_otps()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.phone_otps WHERE expires_at < now() - interval '1 hour';
END;
$$;
