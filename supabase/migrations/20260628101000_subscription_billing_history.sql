-- Add auto_renew column to provider_subscriptions
ALTER TABLE public.provider_subscriptions
  ADD COLUMN IF NOT EXISTS auto_renew BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS renewed_from UUID REFERENCES public.provider_subscriptions(id);

-- Subscription billing history table
CREATE TABLE IF NOT EXISTS public.subscription_billing_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  plan_id UUID NOT NULL REFERENCES public.subscription_plans(id),
  subscription_id UUID REFERENCES public.provider_subscriptions(id),
  amount NUMERIC(10,2) NOT NULL,
  payment_ref TEXT,
  payment_method TEXT DEFAULT 'UPI',
  status TEXT NOT NULL DEFAULT 'paid' CHECK (status IN ('paid','pending','failed','refunded')),
  description TEXT,
  billed_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_billing_history_provider ON public.subscription_billing_history(provider_id);
CREATE INDEX IF NOT EXISTS idx_billing_history_billed_at ON public.subscription_billing_history(billed_at DESC);

ALTER TABLE public.subscription_billing_history ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'subscription_billing_history'
    AND policyname = 'billing_history_provider_access'
  ) THEN
    CREATE POLICY billing_history_provider_access
      ON public.subscription_billing_history FOR ALL
      USING (
        provider_id IN (
          SELECT id FROM public.service_providers WHERE user_id = auth.uid()
        )
      )
      WITH CHECK (
        provider_id IN (
          SELECT id FROM public.service_providers WHERE user_id = auth.uid()
        )
      );
  END IF;
END $$;
