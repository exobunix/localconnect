-- ─── ORDER TRACKING MODULE ────────────────────────────────────────────────────
-- Adds real-time order tracking: timeline steps, provider live location, ETA

-- 1. Tracking status enum
DROP TYPE IF EXISTS public.tracking_step CASCADE;
CREATE TYPE public.tracking_step AS ENUM (
  'confirmed',
  'provider_accepted',
  'en_route',
  'delivered'
);

-- 2. Order tracking table
CREATE TABLE IF NOT EXISTS public.order_tracking (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id          UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  current_step      public.tracking_step NOT NULL DEFAULT 'confirmed'::public.tracking_step,
  provider_lat      NUMERIC DEFAULT NULL,
  provider_lng      NUMERIC DEFAULT NULL,
  eta_minutes       INTEGER DEFAULT NULL,
  confirmed_at      TIMESTAMPTZ DEFAULT NULL,
  accepted_at       TIMESTAMPTZ DEFAULT NULL,
  en_route_at       TIMESTAMPTZ DEFAULT NULL,
  delivered_at      TIMESTAMPTZ DEFAULT NULL,
  provider_note     TEXT DEFAULT '',
  created_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_order_tracking_order_id ON public.order_tracking(order_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_order_tracking_order_unique ON public.order_tracking(order_id);

-- 4. Auto-update updated_at trigger function
CREATE OR REPLACE FUNCTION public.update_order_tracking_timestamp()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

-- 5. Enable RLS
ALTER TABLE public.order_tracking ENABLE ROW LEVEL SECURITY;

-- 6. RLS Policies
DROP POLICY IF EXISTS "customers_view_own_order_tracking" ON public.order_tracking;
CREATE POLICY "customers_view_own_order_tracking"
ON public.order_tracking
FOR SELECT
TO authenticated
USING (
  order_id IN (
    SELECT id FROM public.orders WHERE customer_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "providers_manage_order_tracking" ON public.order_tracking;
CREATE POLICY "providers_manage_order_tracking"
ON public.order_tracking
FOR ALL
TO authenticated
USING (
  order_id IN (
    SELECT o.id FROM public.orders o
    JOIN public.service_providers sp ON sp.id = o.provider_id
    WHERE sp.user_id = auth.uid()
  )
)
WITH CHECK (
  order_id IN (
    SELECT o.id FROM public.orders o
    JOIN public.service_providers sp ON sp.id = o.provider_id
    WHERE sp.user_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "admin_full_access_order_tracking" ON public.order_tracking;
CREATE POLICY "admin_full_access_order_tracking"
ON public.order_tracking
FOR ALL
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE id = auth.uid() AND role = 'admin'
  )
);

-- 7. Trigger for updated_at
DROP TRIGGER IF EXISTS order_tracking_updated_at ON public.order_tracking;
CREATE TRIGGER order_tracking_updated_at
  BEFORE UPDATE ON public.order_tracking
  FOR EACH ROW
  EXECUTE FUNCTION public.update_order_tracking_timestamp();

-- 8. Seed tracking rows for existing active/pending orders
DO $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT id, status FROM public.orders
    WHERE status IN ('active', 'pending', 'upcoming')
  LOOP
    INSERT INTO public.order_tracking (
      order_id,
      current_step,
      provider_lat,
      provider_lng,
      eta_minutes,
      confirmed_at,
      accepted_at
    )
    VALUES (
      rec.id,
      CASE
        WHEN rec.status = 'active' THEN 'provider_accepted'::public.tracking_step
        ELSE 'confirmed'::public.tracking_step
      END,
      18.5204 + (random() * 0.02 - 0.01),
      73.8567 + (random() * 0.02 - 0.01),
      FLOOR(random() * 30 + 10)::INTEGER,
      CURRENT_TIMESTAMP - INTERVAL '10 minutes',
      CASE WHEN rec.status = 'active' THEN CURRENT_TIMESTAMP - INTERVAL '5 minutes' ELSE NULL END
    )
    ON CONFLICT (order_id) DO NOTHING;
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Seed tracking data skipped: %', SQLERRM;
END $$;
