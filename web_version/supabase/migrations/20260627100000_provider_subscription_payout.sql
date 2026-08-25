-- Provider Subscription Plans
CREATE TABLE IF NOT EXISTS public.subscription_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  name_mr TEXT NOT NULL,
  price NUMERIC(10,2) NOT NULL,
  duration_days INTEGER NOT NULL DEFAULT 30,
  features JSONB DEFAULT '[]'::jsonb,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Provider Subscriptions
CREATE TABLE IF NOT EXISTS public.provider_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES public.subscription_plans(id),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','expired','cancelled')),
  started_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  payment_ref TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Provider Payout Requests
CREATE TABLE IF NOT EXISTS public.payout_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  amount NUMERIC(10,2) NOT NULL,
  upi_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','processing','completed','rejected')),
  requested_at TIMESTAMPTZ DEFAULT now(),
  processed_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_provider_subscriptions_provider ON public.provider_subscriptions(provider_id);
CREATE INDEX IF NOT EXISTS idx_payout_requests_provider ON public.payout_requests(provider_id);

-- RLS
ALTER TABLE public.subscription_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payout_requests ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='subscription_plans' AND policyname='plans_public_read') THEN
    CREATE POLICY plans_public_read ON public.subscription_plans FOR SELECT USING (true);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='provider_subscriptions' AND policyname='subs_provider_access') THEN
    CREATE POLICY subs_provider_access ON public.provider_subscriptions FOR ALL
      USING (provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()))
      WITH CHECK (provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='payout_requests' AND policyname='payouts_provider_access') THEN
    CREATE POLICY payouts_provider_access ON public.payout_requests FOR ALL
      USING (provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()))
      WITH CHECK (provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()));
  END IF;
END $$;

-- Seed default plans
INSERT INTO public.subscription_plans (name, name_mr, price, duration_days, features) VALUES
  ('Basic', 'बेसिक', 0, 30, '["5 bookings/month","Basic profile","Customer reviews"]'::jsonb),
  ('Pro', 'प्रो', 299, 30, '["Unlimited bookings","Featured listing","Priority support","Analytics dashboard","Promotional offers"]'::jsonb),
  ('Premium', 'प्रीमियम', 599, 30, '["Everything in Pro","Top search ranking","Verified badge","Dedicated account manager","Early payout"]'::jsonb)
ON CONFLICT DO NOTHING;
