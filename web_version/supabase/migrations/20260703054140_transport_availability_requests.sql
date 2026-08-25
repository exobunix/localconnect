-- Transport Availability & Request Management Migration
-- Adds transport_availability, ride_requests, and notification enhancements

-- ─── Transport Provider Availability ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.transport_availability (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'offline' CHECK (status IN ('available', 'busy', 'offline')),
  vehicle_type TEXT NOT NULL DEFAULT 'rickshaw',
  current_location_lat DOUBLE PRECISION,
  current_location_lng DOUBLE PRECISION,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(provider_id)
);

ALTER TABLE public.transport_availability ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='transport_availability' AND policyname='transport_availability_select') THEN
    CREATE POLICY transport_availability_select ON public.transport_availability FOR SELECT USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='transport_availability' AND policyname='transport_availability_provider_update') THEN
    CREATE POLICY transport_availability_provider_update ON public.transport_availability FOR ALL
      USING (provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()))
      WITH CHECK (provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()));
  END IF;
END $$;

-- ─── Ride Requests (Transport) ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.ride_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  provider_id UUID REFERENCES public.service_providers(id) ON DELETE SET NULL,
  vehicle_type TEXT NOT NULL DEFAULT 'rickshaw',
  pickup_address TEXT NOT NULL DEFAULT '',
  drop_address TEXT NOT NULL DEFAULT '',
  pickup_lat DOUBLE PRECISION,
  pickup_lng DOUBLE PRECISION,
  drop_lat DOUBLE PRECISION,
  drop_lng DOUBLE PRECISION,
  fare_estimate NUMERIC(10,2),
  final_fare NUMERIC(10,2),
  distance_km NUMERIC(8,2),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','rejected','in_progress','completed','cancelled')),
  customer_notes TEXT DEFAULT '',
  provider_notes TEXT DEFAULT '',
  goods_type TEXT DEFAULT '',
  weight_kg NUMERIC(8,2),
  needs_loading BOOLEAN DEFAULT false,
  needs_unloading BOOLEAN DEFAULT false,
  scheduled_at TIMESTAMPTZ,
  accepted_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  cancellation_reason TEXT DEFAULT '',
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  review TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.ride_requests ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='ride_requests' AND policyname='ride_requests_customer_select') THEN
    CREATE POLICY ride_requests_customer_select ON public.ride_requests FOR SELECT
      USING (customer_id = auth.uid() OR provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()));
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='ride_requests' AND policyname='ride_requests_customer_insert') THEN
    CREATE POLICY ride_requests_customer_insert ON public.ride_requests FOR INSERT
      WITH CHECK (customer_id = auth.uid());
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='ride_requests' AND policyname='ride_requests_update') THEN
    CREATE POLICY ride_requests_update ON public.ride_requests FOR UPDATE
      USING (customer_id = auth.uid() OR provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()));
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='ride_requests' AND policyname='ride_requests_admin') THEN
    CREATE POLICY ride_requests_admin ON public.ride_requests FOR ALL
      USING (EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin'));
  END IF;
END $$;

-- ─── Transport Fare Config ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.transport_fare_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  vehicle_type TEXT NOT NULL DEFAULT 'rickshaw',
  fare_type TEXT NOT NULL DEFAULT 'fixed' CHECK (fare_type IN ('fixed','per_km','hourly','custom')),
  base_fare NUMERIC(10,2) DEFAULT 0,
  per_km_charge NUMERIC(10,2) DEFAULT 0,
  per_hour_charge NUMERIC(10,2) DEFAULT 0,
  minimum_fare NUMERIC(10,2) DEFAULT 0,
  waiting_charge_per_min NUMERIC(10,2) DEFAULT 0,
  night_charge_multiplier NUMERIC(4,2) DEFAULT 1.0,
  night_start_hour INTEGER DEFAULT 22,
  night_end_hour INTEGER DEFAULT 6,
  custom_description TEXT DEFAULT '',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(provider_id)
);

ALTER TABLE public.transport_fare_config ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='transport_fare_config' AND policyname='transport_fare_config_select') THEN
    CREATE POLICY transport_fare_config_select ON public.transport_fare_config FOR SELECT USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='transport_fare_config' AND policyname='transport_fare_config_provider_all') THEN
    CREATE POLICY transport_fare_config_provider_all ON public.transport_fare_config FOR ALL
      USING (provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()))
      WITH CHECK (provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()));
  END IF;
END $$;

-- ─── Vehicle Details ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.provider_vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  vehicle_type TEXT NOT NULL DEFAULT 'rickshaw',
  vehicle_number TEXT DEFAULT '',
  vehicle_model TEXT DEFAULT '',
  seating_capacity INTEGER DEFAULT 3,
  load_capacity_kg NUMERIC(8,2),
  insurance_valid_till DATE,
  permit_valid_till DATE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.provider_vehicles ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='provider_vehicles' AND policyname='provider_vehicles_select') THEN
    CREATE POLICY provider_vehicles_select ON public.provider_vehicles FOR SELECT USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='provider_vehicles' AND policyname='provider_vehicles_provider_all') THEN
    CREATE POLICY provider_vehicles_provider_all ON public.provider_vehicles FOR ALL
      USING (provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()))
      WITH CHECK (provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid()));
  END IF;
END $$;

-- ─── Enable Realtime ──────────────────────────────────────────────────────────
DO $$ BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.transport_availability;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.ride_requests;
  EXCEPTION WHEN duplicate_object THEN NULL;
  END;
END $$;

-- ─── Add transport_status to service_providers if not exists ─────────────────
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='service_providers' AND column_name='transport_status') THEN
    ALTER TABLE public.service_providers ADD COLUMN transport_status TEXT DEFAULT 'offline' CHECK (transport_status IN ('available','busy','offline'));
  END IF;
END $$;

-- ─── Add is_transport flag ────────────────────────────────────────────────────
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='service_providers' AND column_name='is_transport') THEN
    ALTER TABLE public.service_providers ADD COLUMN is_transport BOOLEAN DEFAULT false;
  END IF;
END $$;
