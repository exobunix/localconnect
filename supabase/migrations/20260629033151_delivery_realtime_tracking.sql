-- Delivery Realtime Tracking Migration
-- Adds delivery_tracking and rider_locations tables for GPS + status sync

-- ─── TYPES ────────────────────────────────────────────────────────────────────

DROP TYPE IF EXISTS public.delivery_status_type CASCADE;
CREATE TYPE public.delivery_status_type AS ENUM (
  'pending',
  'accepted',
  'picked_up',
  'delivered',
  'cancelled'
);

-- ─── TABLES ───────────────────────────────────────────────────────────────────

-- Delivery tracking: one row per delivery order, updated in real-time
CREATE TABLE IF NOT EXISTS public.delivery_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  delivery_id TEXT NOT NULL UNIQUE,
  rider_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  customer_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  vendor_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  delivery_type TEXT NOT NULL DEFAULT 'general',
  delivery_status public.delivery_status_type NOT NULL DEFAULT 'pending',
  pickup_address TEXT,
  dropoff_address TEXT,
  rider_lat DOUBLE PRECISION,
  rider_lng DOUBLE PRECISION,
  pickup_otp TEXT,
  delivery_otp TEXT,
  amount NUMERIC(10,2) DEFAULT 0,
  rider_earning NUMERIC(10,2) DEFAULT 0,
  accepted_at TIMESTAMPTZ,
  picked_up_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Rider live locations: one row per rider, upserted on GPS update
CREATE TABLE IF NOT EXISTS public.rider_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rider_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  latitude DOUBLE PRECISION NOT NULL DEFAULT 0,
  longitude DOUBLE PRECISION NOT NULL DEFAULT 0,
  is_online BOOLEAN NOT NULL DEFAULT false,
  active_delivery_id TEXT,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT rider_locations_rider_id_unique UNIQUE (rider_id)
);

-- ─── INDEXES ──────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_delivery_tracking_delivery_id ON public.delivery_tracking(delivery_id);
CREATE INDEX IF NOT EXISTS idx_delivery_tracking_rider_id ON public.delivery_tracking(rider_id);
CREATE INDEX IF NOT EXISTS idx_delivery_tracking_customer_id ON public.delivery_tracking(customer_id);
CREATE INDEX IF NOT EXISTS idx_delivery_tracking_vendor_id ON public.delivery_tracking(vendor_id);
CREATE INDEX IF NOT EXISTS idx_delivery_tracking_status ON public.delivery_tracking(delivery_status);
CREATE INDEX IF NOT EXISTS idx_rider_locations_rider_id ON public.rider_locations(rider_id);
CREATE INDEX IF NOT EXISTS idx_rider_locations_online ON public.rider_locations(is_online);

-- ─── FUNCTIONS ────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.update_delivery_tracking_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.update_rider_locations_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

-- ─── RLS ──────────────────────────────────────────────────────────────────────

ALTER TABLE public.delivery_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rider_locations ENABLE ROW LEVEL SECURITY;

-- delivery_tracking: open read for authenticated, write for involved parties
DROP POLICY IF EXISTS "authenticated_read_delivery_tracking" ON public.delivery_tracking;
CREATE POLICY "authenticated_read_delivery_tracking"
ON public.delivery_tracking
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "authenticated_insert_delivery_tracking" ON public.delivery_tracking;
CREATE POLICY "authenticated_insert_delivery_tracking"
ON public.delivery_tracking
FOR INSERT
TO authenticated
WITH CHECK (true);

DROP POLICY IF EXISTS "authenticated_update_delivery_tracking" ON public.delivery_tracking;
CREATE POLICY "authenticated_update_delivery_tracking"
ON public.delivery_tracking
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);

-- rider_locations: open read for authenticated, write only own row
DROP POLICY IF EXISTS "authenticated_read_rider_locations" ON public.rider_locations;
CREATE POLICY "authenticated_read_rider_locations"
ON public.rider_locations
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "rider_manage_own_location" ON public.rider_locations;
CREATE POLICY "rider_manage_own_location"
ON public.rider_locations
FOR ALL
TO authenticated
USING (rider_id = auth.uid())
WITH CHECK (rider_id = auth.uid());

-- ─── TRIGGERS ─────────────────────────────────────────────────────────────────

DROP TRIGGER IF EXISTS delivery_tracking_updated_at ON public.delivery_tracking;
CREATE TRIGGER delivery_tracking_updated_at
  BEFORE UPDATE ON public.delivery_tracking
  FOR EACH ROW
  EXECUTE FUNCTION public.update_delivery_tracking_updated_at();

DROP TRIGGER IF EXISTS rider_locations_updated_at ON public.rider_locations;
CREATE TRIGGER rider_locations_updated_at
  BEFORE UPDATE ON public.rider_locations
  FOR EACH ROW
  EXECUTE FUNCTION public.update_rider_locations_updated_at();

-- ─── ENABLE REALTIME ──────────────────────────────────────────────────────────

-- Add tables to realtime publication
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND tablename = 'delivery_tracking'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.delivery_tracking;
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND tablename = 'rider_locations'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.rider_locations;
  END IF;
END $$;

-- ─── SEED DATA ────────────────────────────────────────────────────────────────

DO $$
DECLARE
  existing_user_id UUID;
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'user_profiles'
  ) THEN
    SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;

    IF existing_user_id IS NOT NULL THEN
      INSERT INTO public.delivery_tracking (
        delivery_id, rider_id, customer_id, vendor_id,
        delivery_type, delivery_status,
        pickup_address, dropoff_address,
        rider_lat, rider_lng,
        pickup_otp, delivery_otp,
        amount, rider_earning
      ) VALUES
        ('DEL001', existing_user_id, existing_user_id, existing_user_id,
         'Food Delivery', 'accepted',
         'Sharma Restaurant, MG Road', 'Sector 5, Pune',
         18.5204, 73.8567, '4521', '7834', 65, 45),
        ('DEL002', existing_user_id, existing_user_id, existing_user_id,
         'Medicine', 'picked_up',
         'City Pharmacy, Camp', 'Koregaon Park',
         18.5314, 73.8446, '3317', '9102', 45, 32)
      ON CONFLICT (delivery_id) DO NOTHING;

      INSERT INTO public.rider_locations (
        rider_id, latitude, longitude, is_online, active_delivery_id
      ) VALUES (
        existing_user_id, 18.5204, 73.8567, true, 'DEL001'
      ) ON CONFLICT (rider_id) DO UPDATE SET
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        is_online = EXCLUDED.is_online;
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Seed data insertion failed: %', SQLERRM;
END $$;
