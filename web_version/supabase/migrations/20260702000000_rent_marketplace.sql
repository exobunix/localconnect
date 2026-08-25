-- ============================================================
-- Rent Marketplace Schema
-- ============================================================

-- Rent subcategory enum
DO $$ BEGIN
  CREATE TYPE rent_subcategory AS ENUM ('room','pg','hostel','hotel','villa','tools');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Rent subscription plan enum
DO $$ BEGIN
  CREATE TYPE rent_plan_type AS ENUM ('free','basic','standard','premium');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Rent listing status enum
DO $$ BEGIN
  CREATE TYPE rent_listing_status AS ENUM ('draft','pending','active','rejected','expired','paused');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Rent inquiry status enum
DO $$ BEGIN
  CREATE TYPE rent_inquiry_status AS ENUM ('pending','accepted','rejected','completed','cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ── Rent Provider Subscriptions ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.rent_provider_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  subcategory rent_subcategory NOT NULL,
  plan_type rent_plan_type NOT NULL DEFAULT 'free',
  max_listings INT NOT NULL DEFAULT 2,
  is_featured_enabled BOOLEAN DEFAULT FALSE,
  is_verified_badge BOOLEAN DEFAULT FALSE,
  is_analytics_enabled BOOLEAN DEFAULT FALSE,
  is_priority_ranking BOOLEAN DEFAULT FALSE,
  price_paid NUMERIC(10,2) DEFAULT 0,
  starts_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  auto_renew BOOLEAN DEFAULT FALSE,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Rent Listings ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.rent_listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  subcategory rent_subcategory NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  price NUMERIC(10,2) NOT NULL,
  price_unit TEXT DEFAULT '/month',
  security_deposit NUMERIC(10,2),
  status rent_listing_status DEFAULT 'pending',
  is_available BOOLEAN DEFAULT TRUE,
  available_from DATE,
  address TEXT,
  city TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  images JSONB DEFAULT '[]',
  amenities JSONB DEFAULT '[]',
  meta JSONB DEFAULT '{}',
  is_featured BOOLEAN DEFAULT FALSE,
  featured_until TIMESTAMPTZ,
  is_verified BOOLEAN DEFAULT FALSE,
  is_sponsored BOOLEAN DEFAULT FALSE,
  views_count INT DEFAULT 0,
  inquiries_count INT DEFAULT 0,
  avg_rating NUMERIC(3,2) DEFAULT 0,
  reviews_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Rent Inquiries / Bookings ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.rent_inquiries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID REFERENCES public.rent_listings(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  provider_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT,
  preferred_date DATE,
  move_in_date DATE,
  status rent_inquiry_status DEFAULT 'pending',
  contact_method TEXT DEFAULT 'chat',
  customer_name TEXT,
  customer_phone TEXT,
  provider_response TEXT,
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Rent Reviews ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.rent_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID REFERENCES public.rent_listings(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  rating INT CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Rent Featured Listings ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.rent_featured_listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID REFERENCES public.rent_listings(id) ON DELETE CASCADE,
  provider_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  duration_days INT NOT NULL DEFAULT 7,
  price_paid NUMERIC(10,2) NOT NULL,
  starts_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Rent Monetization Config (Admin-configurable) ─────────────────────────
CREATE TABLE IF NOT EXISTS public.rent_monetization_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subcategory rent_subcategory NOT NULL,
  plan_type rent_plan_type NOT NULL,
  price_monthly NUMERIC(10,2) DEFAULT 0,
  max_listings INT DEFAULT 2,
  free_listings INT DEFAULT 2,
  featured_7day_price NUMERIC(10,2) DEFAULT 299,
  featured_15day_price NUMERIC(10,2) DEFAULT 499,
  featured_30day_price NUMERIC(10,2) DEFAULT 799,
  verified_badge_price NUMERIC(10,2) DEFAULT 199,
  pay_per_listing_price NUMERIC(10,2) DEFAULT 99,
  is_free_listing_enabled BOOLEAN DEFAULT TRUE,
  is_active BOOLEAN DEFAULT TRUE,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(subcategory, plan_type)
);

-- ── Rent Saved/Favourites ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.rent_favourites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  listing_id UUID REFERENCES public.rent_listings(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(customer_id, listing_id)
);

-- ── Rent Reports ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.rent_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  listing_id UUID REFERENCES public.rent_listings(id) ON DELETE CASCADE,
  reporter_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  details TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Seed Monetization Config ──────────────────────────────────────────────
INSERT INTO public.rent_monetization_config (subcategory, plan_type, price_monthly, max_listings, free_listings)
VALUES
  ('room','free',0,2,2),
  ('room','basic',299,5,2),
  ('room','standard',599,15,2),
  ('room','premium',999,999,2),
  ('pg','free',0,0,0),
  ('pg','basic',499,3,0),
  ('pg','standard',899,10,0),
  ('pg','premium',1499,999,0),
  ('hostel','basic',699,5,0),
  ('hostel','standard',1199,15,0),
  ('hostel','premium',1999,999,0),
  ('hotel','basic',999,5,0),
  ('hotel','standard',1799,20,0),
  ('hotel','premium',2999,999,0),
  ('villa','free',0,1,1),
  ('villa','basic',499,5,1),
  ('villa','standard',999,15,1),
  ('villa','premium',1799,999,1),
  ('tools','free',0,2,2),
  ('tools','basic',399,10,2),
  ('tools','standard',799,30,2),
  ('tools','premium',1299,999,2)
ON CONFLICT (subcategory, plan_type) DO NOTHING;

-- ── RLS Policies ──────────────────────────────────────────────────────────
ALTER TABLE public.rent_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rent_inquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rent_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rent_favourites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rent_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rent_provider_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rent_featured_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rent_monetization_config ENABLE ROW LEVEL SECURITY;

-- Listings: public read, provider write own
CREATE POLICY "rent_listings_public_read" ON public.rent_listings FOR SELECT USING (status = 'active');
CREATE POLICY "rent_listings_provider_all" ON public.rent_listings FOR ALL USING (auth.uid() = provider_id);

-- Inquiries: customer and provider see their own
CREATE POLICY "rent_inquiries_customer" ON public.rent_inquiries FOR ALL USING (auth.uid() = customer_id OR auth.uid() = provider_id);

-- Reviews: public read, customer write own
CREATE POLICY "rent_reviews_public_read" ON public.rent_reviews FOR SELECT USING (TRUE);
CREATE POLICY "rent_reviews_customer_write" ON public.rent_reviews FOR INSERT WITH CHECK (auth.uid() = customer_id);

-- Favourites: customer own
CREATE POLICY "rent_favourites_own" ON public.rent_favourites FOR ALL USING (auth.uid() = customer_id);

-- Reports: customer write
CREATE POLICY "rent_reports_write" ON public.rent_reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);

-- Subscriptions: provider own
CREATE POLICY "rent_subscriptions_own" ON public.rent_provider_subscriptions FOR ALL USING (auth.uid() = provider_id);

-- Monetization config: public read
CREATE POLICY "rent_monetization_public_read" ON public.rent_monetization_config FOR SELECT USING (TRUE);

-- Featured: public read, provider write own
CREATE POLICY "rent_featured_public_read" ON public.rent_featured_listings FOR SELECT USING (TRUE);
CREATE POLICY "rent_featured_provider_write" ON public.rent_featured_listings FOR INSERT WITH CHECK (auth.uid() = provider_id);
