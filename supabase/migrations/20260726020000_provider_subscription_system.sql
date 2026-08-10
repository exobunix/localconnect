-- ─────────────────────────────────────────────────────────────────────────────
-- Provider Subscription System — Full Automated Lifecycle
-- Adds: trial tracking, grace period, reminder notifications, plan enhancements,
--       subscription config table, payment audit log, analytics views
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Enhance subscription_plans with more fields
ALTER TABLE public.subscription_plans
  ADD COLUMN IF NOT EXISTS description TEXT,
  ADD COLUMN IF NOT EXISTS discount_pct NUMERIC(5,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS billing_cycle TEXT DEFAULT 'monthly' CHECK (billing_cycle IN ('monthly','quarterly','yearly','one_time')),
  ADD COLUMN IF NOT EXISTS display_order INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS is_trial BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS trial_days INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS future_features JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- 2. Enhance provider_subscriptions with trial + grace period tracking
ALTER TABLE public.provider_subscriptions
  ADD COLUMN IF NOT EXISTS is_trial BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS trial_start_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS trial_end_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS grace_period_end TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS razorpay_payment_id TEXT,
  ADD COLUMN IF NOT EXISTS razorpay_order_id TEXT,
  ADD COLUMN IF NOT EXISTS razorpay_subscription_id TEXT,
  ADD COLUMN IF NOT EXISTS start_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS end_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- Backfill start_date / end_date from started_at / expires_at
UPDATE public.provider_subscriptions
  SET start_date = started_at, end_date = expires_at
  WHERE start_date IS NULL;

-- 3. Subscription configuration table (admin-controlled settings)
CREATE TABLE IF NOT EXISTS public.subscription_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT UNIQUE NOT NULL,
  value TEXT NOT NULL,
  description TEXT,
  updated_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO public.subscription_config (key, value, description) VALUES
  ('trial_days', '30', 'Free trial duration in days for new providers'),
  ('grace_period_days', '7', 'Grace period after subscription expiry in days'),
  ('reminder_days', '7,3,1', 'Days before expiry to send reminders (comma-separated)'),
  ('auto_renewal_default', 'false', 'Default auto-renewal setting for new subscriptions')
ON CONFLICT (key) DO NOTHING;

ALTER TABLE public.subscription_config ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='subscription_config' AND policyname='config_public_read') THEN
    CREATE POLICY config_public_read ON public.subscription_config FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='subscription_config' AND policyname='config_admin_write') THEN
    CREATE POLICY config_admin_write ON public.subscription_config FOR ALL
      USING (public.is_admin_user())
      WITH CHECK (public.is_admin_user());
  END IF;
END $$;

-- 4. Subscription reminder log (prevents duplicate reminders)
CREATE TABLE IF NOT EXISTS public.subscription_reminders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES public.provider_subscriptions(id) ON DELETE CASCADE,
  reminder_type TEXT NOT NULL, -- '7_days', '3_days', '1_day', 'expired', 'grace_ending'
  sent_at TIMESTAMPTZ DEFAULT now(),
  channel TEXT DEFAULT 'in_app', -- 'in_app', 'push', 'email'
  UNIQUE (provider_id, subscription_id, reminder_type, channel)
);

CREATE INDEX IF NOT EXISTS idx_sub_reminders_provider ON public.subscription_reminders(provider_id);
CREATE INDEX IF NOT EXISTS idx_sub_reminders_sent_at ON public.subscription_reminders(sent_at DESC);

ALTER TABLE public.subscription_reminders ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='subscription_reminders' AND policyname='reminders_provider_read') THEN
    CREATE POLICY reminders_provider_read ON public.subscription_reminders FOR SELECT
      USING (provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()));
  END IF;
END $$;

-- 5. Payment audit log (immutable record of all payment events)
CREATE TABLE IF NOT EXISTS public.subscription_payment_audit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES public.provider_subscriptions(id),
  plan_id UUID REFERENCES public.subscription_plans(id),
  event_type TEXT NOT NULL, -- 'payment_initiated', 'payment_success', 'payment_failed', 'refund', 'trial_start', 'trial_end', 'grace_start', 'grace_end', 'subscription_activated', 'subscription_cancelled'
  razorpay_payment_id TEXT,
  razorpay_order_id TEXT,
  amount NUMERIC(10,2),
  currency TEXT DEFAULT 'INR',
  status TEXT, -- 'success', 'failed', 'pending', 'refunded'
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_payment_audit_provider ON public.subscription_payment_audit(provider_id);
CREATE INDEX IF NOT EXISTS idx_payment_audit_created ON public.subscription_payment_audit(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payment_audit_event ON public.subscription_payment_audit(event_type);

ALTER TABLE public.subscription_payment_audit ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='subscription_payment_audit' AND policyname='audit_provider_read') THEN
    CREATE POLICY audit_provider_read ON public.subscription_payment_audit FOR SELECT
      USING (provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='subscription_payment_audit' AND policyname='audit_admin_all') THEN
    CREATE POLICY audit_admin_all ON public.subscription_payment_audit FOR ALL
      USING (public.is_admin_user());
  END IF;
END $$;

-- 6. Add admin RLS policies for subscription management
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='provider_subscriptions' AND policyname='subs_admin_all') THEN
    CREATE POLICY subs_admin_all ON public.provider_subscriptions FOR ALL
      USING (public.is_admin_user())
      WITH CHECK (public.is_admin_user());
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='subscription_plans' AND policyname='plans_admin_write') THEN
    CREATE POLICY plans_admin_write ON public.subscription_plans FOR ALL
      USING (public.is_admin_user())
      WITH CHECK (public.is_admin_user());
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='subscription_billing_history' AND policyname='billing_admin_all') THEN
    CREATE POLICY billing_admin_all ON public.subscription_billing_history FOR ALL
      USING (public.is_admin_user())
      WITH CHECK (public.is_admin_user());
  END IF;
END $$;

-- 7. Function: auto-assign 30-day free trial when provider is approved
CREATE OR REPLACE FUNCTION public.assign_provider_trial()
RETURNS TRIGGER AS $$
DECLARE
  v_trial_days INTEGER;
  v_trial_plan_id UUID;
  v_existing_sub UUID;
BEGIN
  -- Only trigger when registration_status changes to 'approved'
  IF NEW.registration_status = 'approved' AND (OLD.registration_status IS NULL OR OLD.registration_status <> 'approved') THEN
    -- Get trial duration from config
    SELECT COALESCE(value::INTEGER, 30) INTO v_trial_days
    FROM public.subscription_config WHERE key = 'trial_days';

    -- Check if provider already has any subscription
    SELECT id INTO v_existing_sub
    FROM public.provider_subscriptions
    WHERE provider_id = NEW.id
    LIMIT 1;

    IF v_existing_sub IS NULL THEN
      -- Get or create a trial plan
      SELECT id INTO v_trial_plan_id
      FROM public.subscription_plans
      WHERE is_trial = true AND is_active = true
      LIMIT 1;

      IF v_trial_plan_id IS NULL THEN
        -- Use the first free plan
        SELECT id INTO v_trial_plan_id
        FROM public.subscription_plans
        WHERE price = 0 AND is_active = true
        ORDER BY display_order
        LIMIT 1;
      END IF;

      IF v_trial_plan_id IS NOT NULL THEN
        INSERT INTO public.provider_subscriptions (
          provider_id, plan_id, status, is_trial,
          trial_start_date, trial_end_date,
          start_date, end_date,
          started_at, expires_at,
          auto_renew, payment_ref
        ) VALUES (
          NEW.id, v_trial_plan_id, 'active', true,
          now(), now() + (v_trial_days || ' days')::INTERVAL,
          now(), now() + (v_trial_days || ' days')::INTERVAL,
          now(), now() + (v_trial_days || ' days')::INTERVAL,
          false, 'FREE_TRIAL'
        );

        -- Log audit event
        INSERT INTO public.subscription_payment_audit (
          provider_id, plan_id, event_type, amount, status, metadata
        ) VALUES (
          NEW.id, v_trial_plan_id, 'trial_start', 0, 'success',
          jsonb_build_object('trial_days', v_trial_days, 'auto_assigned', true)
        );
      END IF;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS trg_assign_provider_trial ON public.service_providers;
CREATE TRIGGER trg_assign_provider_trial
  AFTER INSERT OR UPDATE OF registration_status ON public.service_providers
  FOR EACH ROW EXECUTE FUNCTION public.assign_provider_trial();

-- 8. Function: check and update expired subscriptions + grace period
CREATE OR REPLACE FUNCTION public.process_subscription_expiry()
RETURNS void AS $$
DECLARE
  v_grace_days INTEGER;
  v_sub RECORD;
BEGIN
  SELECT COALESCE(value::INTEGER, 7) INTO v_grace_days
  FROM public.subscription_config WHERE key = 'grace_period_days';

  -- Mark active subscriptions as expired when end_date has passed
  FOR v_sub IN
    SELECT ps.id, ps.provider_id, ps.plan_id, ps.end_date, ps.expires_at
    FROM public.provider_subscriptions ps
    WHERE ps.status = 'active'
      AND COALESCE(ps.end_date, ps.expires_at) < now()
  LOOP
    UPDATE public.provider_subscriptions
    SET
      status = 'expired',
      grace_period_end = COALESCE(v_sub.end_date, v_sub.expires_at) + (v_grace_days || ' days')::INTERVAL,
      updated_at = now()
    WHERE id = v_sub.id;

    INSERT INTO public.subscription_payment_audit (
      provider_id, subscription_id, plan_id, event_type, status, metadata
    ) VALUES (
      v_sub.provider_id, v_sub.id, v_sub.plan_id, 'grace_start', 'info',
      jsonb_build_object('grace_days', v_grace_days, 'grace_end', (COALESCE(v_sub.end_date, v_sub.expires_at) + (v_grace_days || ' days')::INTERVAL))
    ) ON CONFLICT DO NOTHING;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Update subscription_plans seed data with enhanced fields
UPDATE public.subscription_plans SET
  billing_cycle = 'monthly',
  display_order = 1,
  is_trial = false,
  description = 'Get started with basic features',
  future_features = '["Featured Provider Badge","Priority Search Ranking","Unlimited Services","Unlimited Images","Promotional Campaign Credits","Premium Analytics","Featured Listings"]'::jsonb
WHERE name = 'Basic' AND description IS NULL;

UPDATE public.subscription_plans SET
  billing_cycle = 'monthly',
  display_order = 2,
  is_trial = false,
  description = 'Grow your business with premium tools'
WHERE name = 'Pro' AND description IS NULL;

UPDATE public.subscription_plans SET
  billing_cycle = 'monthly',
  display_order = 3,
  is_trial = false,
  description = 'Maximum visibility and priority support'
WHERE name = 'Premium' AND description IS NULL;

-- Insert quarterly and yearly plans
INSERT INTO public.subscription_plans (name, name_mr, price, duration_days, billing_cycle, display_order, description, discount_pct, features, is_active) VALUES
  ('Pro Quarterly', 'प्रो त्रैमासिक', 799, 90, 'quarterly', 4, 'Pro features for 3 months — save 11%', 11, '["Unlimited bookings","Featured listing","Priority support","Analytics dashboard","Promotional offers","Save 11% vs monthly"]'::jsonb, true),
  ('Pro Yearly', 'प्रो वार्षिक', 2499, 365, 'yearly', 5, 'Pro features for 1 year — save 30%', 30, '["Unlimited bookings","Featured listing","Priority support","Analytics dashboard","Promotional offers","Save 30% vs monthly"]'::jsonb, true),
  ('Premium Yearly', 'प्रीमियम वार्षिक', 4999, 365, 'yearly', 6, 'Premium features for 1 year — best value', 30, '["Everything in Premium","Top search ranking","Verified badge","Dedicated account manager","Early payout","Save 30% vs monthly"]'::jsonb, true)
ON CONFLICT DO NOTHING;

-- Mark Basic plan as trial-eligible
UPDATE public.subscription_plans SET is_trial = true, trial_days = 30 WHERE name = 'Basic';

-- 10. Indexes for performance
CREATE INDEX IF NOT EXISTS idx_provider_subs_status ON public.provider_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_provider_subs_end_date ON public.provider_subscriptions(end_date);
CREATE INDEX IF NOT EXISTS idx_provider_subs_trial ON public.provider_subscriptions(is_trial);
CREATE INDEX IF NOT EXISTS idx_provider_subs_grace ON public.provider_subscriptions(grace_period_end);
