-- Referral System Migration
-- Creates tables for referral codes, tracking, analytics, and admin config

-- ── Referral Config (Admin-controlled) ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.referral_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  is_enabled BOOLEAN NOT NULL DEFAULT true,
  reward_type TEXT NOT NULL DEFAULT 'none', -- 'none', 'discount', 'credits', 'cash'
  reward_value NUMERIC(10,2) NOT NULL DEFAULT 0,
  reward_description TEXT DEFAULT '',
  max_referrals_per_user INTEGER DEFAULT 100,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default config
INSERT INTO public.referral_config (is_enabled, reward_type, reward_value, reward_description)
VALUES (true, 'none', 0, 'Referral program active - rewards coming soon!')
ON CONFLICT DO NOTHING;

-- ── User Referral Codes ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_referral_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  referral_code TEXT NOT NULL UNIQUE,
  total_clicks INTEGER NOT NULL DEFAULT 0,
  total_registrations INTEGER NOT NULL DEFAULT 0,
  total_rewards_earned NUMERIC(10,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_referral_codes_user_id ON public.user_referral_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_user_referral_codes_code ON public.user_referral_codes(referral_code);

-- ── Referral Registrations ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.referral_registrations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referral_code TEXT NOT NULL,
  referrer_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  referred_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  referred_email TEXT,
  referred_phone TEXT,
  status TEXT NOT NULL DEFAULT 'registered', -- 'clicked', 'registered', 'verified'
  reward_given BOOLEAN NOT NULL DEFAULT false,
  reward_amount NUMERIC(10,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_referral_registrations_referrer ON public.referral_registrations(referrer_user_id);
CREATE INDEX IF NOT EXISTS idx_referral_registrations_code ON public.referral_registrations(referral_code);

-- ── Share Analytics ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.share_analytics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  share_type TEXT NOT NULL, -- 'app', 'provider_profile', 'referral'
  platform TEXT, -- 'whatsapp', 'facebook', 'instagram', 'telegram', 'sms', 'email', 'native', 'copy'
  provider_id UUID REFERENCES public.service_providers(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_share_analytics_user_id ON public.share_analytics(user_id);
CREATE INDEX IF NOT EXISTS idx_share_analytics_type ON public.share_analytics(share_type);

-- ── RLS Policies ─────────────────────────────────────────────────────────────

ALTER TABLE public.referral_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_referral_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referral_registrations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.share_analytics ENABLE ROW LEVEL SECURITY;

-- referral_config: anyone can read, only admin can write
CREATE POLICY "Anyone can read referral config"
  ON public.referral_config FOR SELECT USING (true);

CREATE POLICY "Admins can manage referral config"
  ON public.referral_config FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid() AND user_profiles.role = 'admin'
    )
  );

-- user_referral_codes: users can read their own, admins can read all
CREATE POLICY "Users can read own referral code"
  ON public.user_referral_codes FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own referral code"
  ON public.user_referral_codes FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own referral code"
  ON public.user_referral_codes FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Admins can read all referral codes"
  ON public.user_referral_codes FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid() AND user_profiles.role = 'admin'
    )
  );

-- referral_registrations: referrer can read their own
CREATE POLICY "Referrers can read own registrations"
  ON public.referral_registrations FOR SELECT
  USING (referrer_user_id = auth.uid());

CREATE POLICY "Authenticated users can insert referral registrations"
  ON public.referral_registrations FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Admins can read all referral registrations"
  ON public.referral_registrations FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid() AND user_profiles.role = 'admin'
    )
  );

-- share_analytics: users can insert their own
CREATE POLICY "Users can insert share analytics"
  ON public.share_analytics FOR INSERT
  WITH CHECK (user_id = auth.uid() OR user_id IS NULL);

CREATE POLICY "Users can read own share analytics"
  ON public.share_analytics FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Admins can read all share analytics"
  ON public.share_analytics FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE user_profiles.id = auth.uid() AND user_profiles.role = 'admin'
    )
  );

-- ── Function: Generate Referral Code ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.generate_referral_code(p_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_code TEXT;
  v_exists BOOLEAN;
  v_attempts INTEGER := 0;
BEGIN
  -- Check if user already has a code
  SELECT referral_code INTO v_code
  FROM public.user_referral_codes
  WHERE user_id = p_user_id;
  
  IF v_code IS NOT NULL THEN
    RETURN v_code;
  END IF;
  
  -- Generate unique code
  LOOP
    v_code := UPPER(SUBSTRING(MD5(p_user_id::TEXT || NOW()::TEXT || v_attempts::TEXT) FROM 1 FOR 8));
    SELECT EXISTS(SELECT 1 FROM public.user_referral_codes WHERE referral_code = v_code) INTO v_exists;
    EXIT WHEN NOT v_exists;
    v_attempts := v_attempts + 1;
    IF v_attempts > 10 THEN
      RAISE EXCEPTION 'Could not generate unique referral code';
    END IF;
  END LOOP;
  
  -- Insert the code
  INSERT INTO public.user_referral_codes (user_id, referral_code)
  VALUES (p_user_id, v_code);
  
  RETURN v_code;
END;
$$;
