-- Fix phone_otps RLS: the previous policy blocked ALL access including service role via REST API
-- Drop the blocking policy and disable RLS so service role key can access freely
ALTER TABLE public.phone_otps DISABLE ROW LEVEL SECURITY;

-- Drop the old blocking policy if it exists
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'phone_otps' AND policyname = 'service_role_only'
  ) THEN
    DROP POLICY service_role_only ON public.phone_otps;
  END IF;
END $$;
