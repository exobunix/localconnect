-- ─── REVIEWS TABLE ───────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  provider_id UUID REFERENCES public.service_providers(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  review_text TEXT DEFAULT '',
  provider_name TEXT DEFAULT '',
  service TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(order_id)
);

ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'reviews' AND policyname = 'customers_insert_reviews'
  ) THEN
    CREATE POLICY customers_insert_reviews ON public.reviews
      FOR INSERT TO authenticated
      WITH CHECK (auth.uid() = customer_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'reviews' AND policyname = 'customers_read_own_reviews'
  ) THEN
    CREATE POLICY customers_read_own_reviews ON public.reviews
      FOR SELECT TO authenticated
      USING (auth.uid() = customer_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'reviews' AND policyname = 'providers_read_their_reviews'
  ) THEN
    CREATE POLICY providers_read_their_reviews ON public.reviews
      FOR SELECT TO authenticated
      USING (
        provider_id IN (
          SELECT id FROM public.service_providers WHERE user_id = auth.uid()
        )
      );
  END IF;
END $$;

-- ─── NOTIFICATIONS TABLE ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT '',
  body TEXT NOT NULL DEFAULT '',
  type TEXT DEFAULT 'general',
  is_read BOOLEAN DEFAULT FALSE,
  related_id TEXT DEFAULT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'users_read_own_notifications'
  ) THEN
    CREATE POLICY users_read_own_notifications ON public.notifications
      FOR SELECT TO authenticated
      USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'users_update_own_notifications'
  ) THEN
    CREATE POLICY users_update_own_notifications ON public.notifications
      FOR UPDATE TO authenticated
      USING (auth.uid() = user_id);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'service_insert_notifications'
  ) THEN
    CREATE POLICY service_insert_notifications ON public.notifications
      FOR INSERT TO authenticated
      WITH CHECK (true);
  END IF;
END $$;

-- Add reviewed column to orders if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'orders' AND column_name = 'reviewed'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN reviewed BOOLEAN DEFAULT FALSE;
  END IF;
END $$;
