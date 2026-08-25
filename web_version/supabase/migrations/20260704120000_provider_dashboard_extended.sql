-- Provider Dashboard Extended Profile Migration
-- Adds extended profile fields, service charge tables, event portfolio, and favorites

-- ─── Extended Provider Profile Columns ───────────────────────────────────────
ALTER TABLE public.service_providers
  ADD COLUMN IF NOT EXISTS cover_image_url TEXT,
  ADD COLUMN IF NOT EXISTS business_logo_url TEXT,
  ADD COLUMN IF NOT EXISTS business_description TEXT,
  ADD COLUMN IF NOT EXISTS years_experience INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS working_hours TEXT DEFAULT '9:00 AM - 6:00 PM',
  ADD COLUMN IF NOT EXISTS service_area TEXT,
  ADD COLUMN IF NOT EXISTS languages_spoken TEXT[] DEFAULT ARRAY['Hindi', 'English'],
  ADD COLUMN IF NOT EXISTS whatsapp_number TEXT,
  ADD COLUMN IF NOT EXISTS emergency_contact TEXT,
  ADD COLUMN IF NOT EXISTS google_map_url TEXT,
  ADD COLUMN IF NOT EXISTS address TEXT,
  ADD COLUMN IF NOT EXISTS completed_jobs INTEGER DEFAULT 0,
  ADD COLUMN IF NOT EXISTS response_time TEXT DEFAULT 'Within 1 hour',
  ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS gallery_photos TEXT[] DEFAULT ARRAY[]::TEXT[];

-- ─── Home Maintenance Service Charges ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.provider_service_charges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID REFERENCES public.service_providers(id) ON DELETE CASCADE,
  service_name TEXT NOT NULL,
  description TEXT,
  base_price NUMERIC(10,2) DEFAULT 0,
  unit TEXT DEFAULT 'per visit',
  is_emergency BOOLEAN DEFAULT false,
  is_enabled BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_provider_service_charges_provider_id
  ON public.provider_service_charges(provider_id);

-- ─── Transport Extended Fare Config Columns ───────────────────────────────────
ALTER TABLE public.transport_fare_config
  ADD COLUMN IF NOT EXISTS night_charge NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS hourly_package NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS daily_package NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS outstation_fare NUMERIC(10,2) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS toll_charges TEXT DEFAULT 'As applicable',
  ADD COLUMN IF NOT EXISTS parking_charges TEXT DEFAULT 'As applicable',
  ADD COLUMN IF NOT EXISTS extra_charges TEXT,
  ADD COLUMN IF NOT EXISTS ac_available BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

-- ─── Event Management Portfolio ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.provider_portfolio (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID REFERENCES public.service_providers(id) ON DELETE CASCADE,
  photo_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
  instagram_reel_links TEXT[] DEFAULT ARRAY[]::TEXT[],
  instagram_post_links TEXT[] DEFAULT ARRAY[]::TEXT[],
  youtube_links TEXT[] DEFAULT ARRAY[]::TEXT[],
  portfolio_description TEXT,
  events_completed INTEGER DEFAULT 0,
  available_cities TEXT[] DEFAULT ARRAY[]::TEXT[],
  travel_charges TEXT,
  starting_price NUMERIC(10,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_provider_portfolio_provider_id
  ON public.provider_portfolio(provider_id);

-- ─── Event Packages ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.provider_packages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID REFERENCES public.service_providers(id) ON DELETE CASCADE,
  package_name TEXT NOT NULL,
  package_type TEXT DEFAULT 'basic',
  price NUMERIC(10,2) DEFAULT 0,
  duration TEXT,
  description TEXT,
  features TEXT[] DEFAULT ARRAY[]::TEXT[],
  deliverables TEXT[] DEFAULT ARRAY[]::TEXT[],
  is_popular BOOLEAN DEFAULT false,
  is_enabled BOOLEAN DEFAULT true,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_provider_packages_provider_id
  ON public.provider_packages(provider_id);

-- ─── Customer Favorites ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.customer_favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  provider_id UUID REFERENCES public.service_providers(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_customer_favorites_unique
  ON public.customer_favorites(customer_id, provider_id);

CREATE INDEX IF NOT EXISTS idx_customer_favorites_customer_id
  ON public.customer_favorites(customer_id);

-- ─── RLS ──────────────────────────────────────────────────────────────────────
ALTER TABLE public.provider_service_charges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.provider_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_favorites ENABLE ROW LEVEL SECURITY;

-- Helper function to get provider_id for current user
CREATE OR REPLACE FUNCTION public.get_my_provider_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT id FROM public.service_providers WHERE user_id = auth.uid() LIMIT 1;
$$;

-- Service Charges: provider owns, customers can read
DROP POLICY IF EXISTS "provider_manage_service_charges" ON public.provider_service_charges;
CREATE POLICY "provider_manage_service_charges"
  ON public.provider_service_charges FOR ALL TO authenticated
  USING (provider_id = public.get_my_provider_id())
  WITH CHECK (provider_id = public.get_my_provider_id());

DROP POLICY IF EXISTS "public_read_service_charges" ON public.provider_service_charges;
CREATE POLICY "public_read_service_charges"
  ON public.provider_service_charges FOR SELECT TO public
  USING (true);

-- Portfolio: provider owns, customers can read
DROP POLICY IF EXISTS "provider_manage_portfolio" ON public.provider_portfolio;
CREATE POLICY "provider_manage_portfolio"
  ON public.provider_portfolio FOR ALL TO authenticated
  USING (provider_id = public.get_my_provider_id())
  WITH CHECK (provider_id = public.get_my_provider_id());

DROP POLICY IF EXISTS "public_read_portfolio" ON public.provider_portfolio;
CREATE POLICY "public_read_portfolio"
  ON public.provider_portfolio FOR SELECT TO public
  USING (true);

-- Packages: provider owns, customers can read
DROP POLICY IF EXISTS "provider_manage_packages" ON public.provider_packages;
CREATE POLICY "provider_manage_packages"
  ON public.provider_packages FOR ALL TO authenticated
  USING (provider_id = public.get_my_provider_id())
  WITH CHECK (provider_id = public.get_my_provider_id());

DROP POLICY IF EXISTS "public_read_packages" ON public.provider_packages;
CREATE POLICY "public_read_packages"
  ON public.provider_packages FOR SELECT TO public
  USING (true);

-- Favorites: customers manage their own
DROP POLICY IF EXISTS "customers_manage_favorites" ON public.customer_favorites;
CREATE POLICY "customers_manage_favorites"
  ON public.customer_favorites FOR ALL TO authenticated
  USING (customer_id = auth.uid())
  WITH CHECK (customer_id = auth.uid());
