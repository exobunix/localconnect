-- Create admin_email_otps table for custom email OTP flow
CREATE TABLE IF NOT EXISTS public.admin_email_otps (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  email text NOT NULL,
  otp text NOT NULL,
  expires_at timestamptz NOT NULL,
  verified boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

-- Index for fast lookup
CREATE INDEX IF NOT EXISTS idx_admin_email_otps_email ON public.admin_email_otps(email);

-- RLS: only service role can access
ALTER TABLE public.admin_email_otps ENABLE ROW LEVEL SECURITY;

-- No public access — Edge Function uses service role key
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'admin_email_otps' AND policyname = 'service_role_only'
  ) THEN
    CREATE POLICY "service_role_only" ON public.admin_email_otps
      USING (false);
  END IF;
END $$;

-- Auto-cleanup expired OTPs older than 1 hour
CREATE OR REPLACE FUNCTION public.cleanup_admin_email_otps()
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  DELETE FROM public.admin_email_otps
  WHERE expires_at < now() - interval '1 hour';
END;
$$;
