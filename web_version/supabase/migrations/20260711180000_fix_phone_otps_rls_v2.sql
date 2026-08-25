-- Fix phone_otps RLS v2: ensure service role can access the table via REST API
-- The previous migration was discarded; this re-applies the fix with a higher timestamp

-- Disable RLS so the service role key used by edge functions can freely read/write
ALTER TABLE public.phone_otps DISABLE ROW LEVEL SECURITY;

-- Drop the blocking policy if it still exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'phone_otps' AND policyname = 'service_role_only'
  ) THEN
    DROP POLICY service_role_only ON public.phone_otps;
  END IF;
END $$;

-- Ensure the unique index on phone exists (required for DELETE+INSERT pattern to be safe)
CREATE UNIQUE INDEX IF NOT EXISTS phone_otps_phone_idx ON public.phone_otps (phone);
