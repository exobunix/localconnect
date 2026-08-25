-- Provider Offers / Discounts / Promotional Codes
-- Migration: 20260624220000_provider_offers.sql

CREATE TABLE IF NOT EXISTS public.provider_offers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  discount_type TEXT NOT NULL DEFAULT 'percentage', -- 'percentage' | 'flat'
  discount_value NUMERIC(10, 2) NOT NULL DEFAULT 0,
  promo_code TEXT,
  min_order_amount NUMERIC(10, 2) DEFAULT 0,
  max_discount_amount NUMERIC(10, 2),
  starts_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  usage_limit INT,
  usage_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_provider_offers_provider_id ON public.provider_offers(provider_id);
CREATE INDEX IF NOT EXISTS idx_provider_offers_expires_at ON public.provider_offers(expires_at);
CREATE INDEX IF NOT EXISTS idx_provider_offers_is_active ON public.provider_offers(is_active);

ALTER TABLE public.provider_offers ENABLE ROW LEVEL SECURITY;

-- Public can read active, non-expired offers
DROP POLICY IF EXISTS "public_read_active_offers" ON public.provider_offers;
CREATE POLICY "public_read_active_offers"
ON public.provider_offers
FOR SELECT
TO public
USING (is_active = true AND expires_at > now());

-- Providers manage their own offers (via service_providers ownership)
DROP POLICY IF EXISTS "providers_manage_own_offers" ON public.provider_offers;
CREATE POLICY "providers_manage_own_offers"
ON public.provider_offers
FOR ALL
TO authenticated
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

-- Updated_at trigger
CREATE OR REPLACE FUNCTION public.update_provider_offers_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_provider_offers_updated_at ON public.provider_offers;
CREATE TRIGGER trg_provider_offers_updated_at
BEFORE UPDATE ON public.provider_offers
FOR EACH ROW EXECUTE FUNCTION public.update_provider_offers_updated_at();

-- Sample offers linked to existing providers
DO $$
DECLARE
  existing_provider_id UUID;
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'service_providers'
  ) THEN
    SELECT id INTO existing_provider_id FROM public.service_providers LIMIT 1;
    IF existing_provider_id IS NOT NULL THEN
      INSERT INTO public.provider_offers (
        provider_id, title, description, discount_type, discount_value,
        promo_code, min_order_amount, starts_at, expires_at, is_active
      ) VALUES
        (existing_provider_id, 'Monsoon Special 20% Off', 'Get 20% off on all services this monsoon season', 'percentage', 20,
         'MONSOON20', 200, now(), now() + INTERVAL '30 days', true),
        (existing_provider_id, 'First Visit Flat ₹100 Off', 'New customers get ₹100 off on first booking', 'flat', 100,
         'FIRST100', 300, now(), now() + INTERVAL '60 days', true)
      ON CONFLICT (id) DO NOTHING;
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Sample offers insertion skipped: %', SQLERRM;
END $$;
