-- Create phone_otps table for Twilio OTP verification
CREATE TABLE IF NOT EXISTS public.phone_otps (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  phone text NOT NULL,
  otp text NOT NULL,
  expires_at timestamptz NOT NULL,
  verified boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Unique constraint on phone so upsert works
CREATE UNIQUE INDEX IF NOT EXISTS phone_otps_phone_idx ON public.phone_otps (phone);

-- RLS: only service role can access (edge functions use service role key)
ALTER TABLE public.phone_otps ENABLE ROW LEVEL SECURITY;

-- No public access — all access via edge functions with service role key
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'phone_otps' AND policyname = 'service_role_only'
  ) THEN
    CREATE POLICY service_role_only ON public.phone_otps
      USING (false)
      WITH CHECK (false);
  END IF;
END $$;

-- Auto-cleanup expired OTPs (optional, runs via cron or can be manual)
CREATE OR REPLACE FUNCTION public.cleanup_expired_otps()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.phone_otps WHERE expires_at < now() - interval '1 hour';
END;
$$;
