-- Provider Earnings Dashboard Migration
-- Adds earnings_records table for detailed earnings tracking

CREATE TABLE IF NOT EXISTS public.earnings_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  amount NUMERIC(10, 2) NOT NULL DEFAULT 0,
  type TEXT NOT NULL DEFAULT 'order' CHECK (type IN ('order', 'bonus', 'penalty', 'withdrawal')),
  description TEXT,
  status TEXT NOT NULL DEFAULT 'credited' CHECK (status IN ('credited', 'pending', 'withdrawn')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast provider earnings queries
CREATE INDEX IF NOT EXISTS idx_earnings_provider_id ON public.earnings_records(provider_id);
CREATE INDEX IF NOT EXISTS idx_earnings_created_at ON public.earnings_records(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_earnings_provider_created ON public.earnings_records(provider_id, created_at DESC);

-- RLS
ALTER TABLE public.earnings_records ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'earnings_records' AND policyname = 'Providers can view own earnings'
  ) THEN
    CREATE POLICY "Providers can view own earnings"
      ON public.earnings_records FOR SELECT
      USING (
        provider_id IN (
          SELECT id FROM public.service_providers WHERE user_id = auth.uid()
        )
      );
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'earnings_records' AND policyname = 'System can insert earnings'
  ) THEN
    CREATE POLICY "System can insert earnings"
      ON public.earnings_records FOR INSERT
      WITH CHECK (
        provider_id IN (
          SELECT id FROM public.service_providers WHERE user_id = auth.uid()
        )
      );
  END IF;
END $$;
