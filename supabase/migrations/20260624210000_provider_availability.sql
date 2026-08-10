-- ─── Provider Availability: Working Hours, Days Off, Booking Slots ───────────

-- 1. Working hours per day of week (0=Sun, 1=Mon, ..., 6=Sat)
CREATE TABLE IF NOT EXISTS public.provider_working_hours (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id   UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  day_of_week   SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  is_open       BOOLEAN NOT NULL DEFAULT true,
  open_time     TIME NOT NULL DEFAULT '09:00',
  close_time    TIME NOT NULL DEFAULT '18:00',
  slot_duration_minutes SMALLINT NOT NULL DEFAULT 60,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (provider_id, day_of_week)
);

-- 2. Days off (specific dates the provider is unavailable)
CREATE TABLE IF NOT EXISTS public.provider_days_off (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id   UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  off_date      DATE NOT NULL,
  reason        TEXT DEFAULT '',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (provider_id, off_date)
);

-- 3. Booking slots (auto-generated or manually managed)
CREATE TABLE IF NOT EXISTS public.provider_booking_slots (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id   UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  slot_date     DATE NOT NULL,
  slot_time     TIME NOT NULL,
  is_available  BOOLEAN NOT NULL DEFAULT true,
  is_booked     BOOLEAN NOT NULL DEFAULT false,
  order_id      UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (provider_id, slot_date, slot_time)
);

-- ─── Indexes ──────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_working_hours_provider ON public.provider_working_hours(provider_id);
CREATE INDEX IF NOT EXISTS idx_days_off_provider_date ON public.provider_days_off(provider_id, off_date);
CREATE INDEX IF NOT EXISTS idx_booking_slots_provider_date ON public.provider_booking_slots(provider_id, slot_date);

-- ─── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.provider_working_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_days_off ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_booking_slots ENABLE ROW LEVEL SECURITY;

-- Working hours: public read, provider write
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='provider_working_hours' AND policyname='working_hours_public_read') THEN
    CREATE POLICY working_hours_public_read ON public.provider_working_hours
      FOR SELECT USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='provider_working_hours' AND policyname='working_hours_provider_write') THEN
    CREATE POLICY working_hours_provider_write ON public.provider_working_hours
      FOR ALL USING (
        provider_id IN (
          SELECT id FROM public.service_providers WHERE user_id = auth.uid()
        )
      );
  END IF;
END $$;

-- Days off: public read, provider write
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='provider_days_off' AND policyname='days_off_public_read') THEN
    CREATE POLICY days_off_public_read ON public.provider_days_off
      FOR SELECT USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='provider_days_off' AND policyname='days_off_provider_write') THEN
    CREATE POLICY days_off_provider_write ON public.provider_days_off
      FOR ALL USING (
        provider_id IN (
          SELECT id FROM public.service_providers WHERE user_id = auth.uid()
        )
      );
  END IF;
END $$;

-- Booking slots: public read, provider write
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='provider_booking_slots' AND policyname='booking_slots_public_read') THEN
    CREATE POLICY booking_slots_public_read ON public.provider_booking_slots
      FOR SELECT USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename='provider_booking_slots' AND policyname='booking_slots_provider_write') THEN
    CREATE POLICY booking_slots_provider_write ON public.provider_booking_slots
      FOR ALL USING (
        provider_id IN (
          SELECT id FROM public.service_providers WHERE user_id = auth.uid()
        )
      );
  END IF;
END $$;
