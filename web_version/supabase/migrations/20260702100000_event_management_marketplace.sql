-- Event Management Marketplace Schema
-- Migration: 20260702100000_event_management_marketplace

-- ── Event Providers ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.event_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  business_name TEXT NOT NULL,
  subcategory TEXT NOT NULL,
  description TEXT,
  cover_image TEXT,
  logo_image TEXT,
  starting_price NUMERIC(12,2),
  max_price NUMERIC(12,2),
  experience_years INTEGER DEFAULT 0,
  location TEXT,
  latitude NUMERIC(10,7),
  longitude NUMERIC(10,7),
  travel_distance_km INTEGER DEFAULT 50,
  contact_phone TEXT,
  whatsapp_number TEXT,
  business_hours JSONB DEFAULT '{}',
  languages_spoken TEXT[] DEFAULT '{}',
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  is_featured BOOLEAN DEFAULT FALSE,
  is_sponsored BOOLEAN DEFAULT FALSE,
  avg_rating NUMERIC(3,2) DEFAULT 0,
  total_reviews INTEGER DEFAULT 0,
  total_bookings INTEGER DEFAULT 0,
  subcategory_details JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Event Provider Portfolio ──────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.event_portfolio (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID REFERENCES public.event_providers(id) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  media_type TEXT DEFAULT 'image',
  caption TEXT,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Event Services ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.event_services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID REFERENCES public.event_providers(id) ON DELETE CASCADE,
  service_name TEXT NOT NULL,
  description TEXT,
  price NUMERIC(12,2),
  price_unit TEXT DEFAULT 'fixed',
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Event Inquiries / Bookings ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.event_inquiries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID REFERENCES public.event_providers(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  customer_name TEXT NOT NULL,
  customer_phone TEXT NOT NULL,
  event_type TEXT,
  event_date DATE,
  event_location TEXT,
  guest_count INTEGER,
  budget_range TEXT,
  message TEXT,
  preferred_contact TEXT DEFAULT 'chat',
  status TEXT DEFAULT 'pending',
  provider_response TEXT,
  negotiated_price NUMERIC(12,2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Event Reviews ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.event_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID REFERENCES public.event_providers(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  customer_name TEXT NOT NULL,
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Event Favourites ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.event_favourites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  provider_id UUID REFERENCES public.event_providers(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(customer_id, provider_id)
);

-- ── Event Reports ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.event_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  provider_id UUID REFERENCES public.event_providers(id) ON DELETE CASCADE,
  reason TEXT NOT NULL,
  details TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Event Provider Subscriptions ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.event_provider_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID REFERENCES public.event_providers(id) ON DELETE CASCADE,
  plan_name TEXT NOT NULL,
  subcategory TEXT NOT NULL,
  amount_paid NUMERIC(12,2),
  duration_days INTEGER DEFAULT 30,
  starts_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  status TEXT DEFAULT 'active',
  payment_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Event Featured Listings ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.event_featured_listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID REFERENCES public.event_providers(id) ON DELETE CASCADE,
  duration_days INTEGER DEFAULT 7,
  amount_paid NUMERIC(12,2),
  starts_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Event Monetization Config (Admin Configurable) ────────────────────────
CREATE TABLE IF NOT EXISTS public.event_monetization_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subcategory TEXT UNIQUE NOT NULL,
  free_listings_enabled BOOLEAN DEFAULT TRUE,
  free_listings_count INTEGER DEFAULT 1,
  monetization_model TEXT DEFAULT 'subscription',
  basic_plan_price NUMERIC(10,2) DEFAULT 299,
  standard_plan_price NUMERIC(10,2) DEFAULT 599,
  premium_plan_price NUMERIC(10,2) DEFAULT 999,
  basic_plan_listings INTEGER DEFAULT 3,
  standard_plan_listings INTEGER DEFAULT 10,
  premium_plan_listings INTEGER DEFAULT -1,
  featured_7day_price NUMERIC(10,2) DEFAULT 199,
  featured_15day_price NUMERIC(10,2) DEFAULT 349,
  featured_30day_price NUMERIC(10,2) DEFAULT 599,
  sponsored_listing_price NUMERIC(10,2) DEFAULT 499,
  verified_badge_price NUMERIC(10,2) DEFAULT 999,
  pay_per_lead_price NUMERIC(10,2) DEFAULT 49,
  pay_per_lead_enabled BOOLEAN DEFAULT FALSE,
  verified_badge_enabled BOOLEAN DEFAULT TRUE,
  featured_count_displayed INTEGER DEFAULT 5,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ── Seed Monetization Config for all 17 subcategories ────────────────────
INSERT INTO public.event_monetization_config (subcategory, monetization_model, basic_plan_price, standard_plan_price, premium_plan_price, pay_per_lead_enabled, verified_badge_enabled)
VALUES
  ('photography', 'subscription', 299, 599, 999, FALSE, TRUE),
  ('videography', 'subscription', 299, 599, 999, FALSE, TRUE),
  ('sound', 'subscription', 249, 499, 799, FALSE, FALSE),
  ('mandap', 'subscription', 499, 899, 1499, FALSE, TRUE),
  ('birthday', 'subscription', 199, 399, 699, FALSE, FALSE),
  ('catering', 'subscription', 499, 899, 1499, FALSE, TRUE),
  ('makeup', 'hybrid', 199, 399, 699, TRUE, FALSE),
  ('mehendi', 'hybrid', 149, 299, 499, TRUE, FALSE),
  ('lighting', 'subscription', 249, 499, 799, FALSE, FALSE),
  ('planner', 'subscription', 499, 999, 1999, FALSE, TRUE),
  ('anchor', 'hybrid', 149, 299, 499, TRUE, FALSE),
  ('band', 'subscription', 299, 599, 999, FALSE, FALSE),
  ('orchestra', 'subscription', 299, 599, 999, FALSE, FALSE),
  ('dance', 'subscription', 249, 499, 799, FALSE, FALSE),
  ('generator', 'subscription', 199, 399, 699, FALSE, FALSE),
  ('chair_table', 'subscription', 149, 299, 499, FALSE, FALSE),
  ('tent', 'subscription', 399, 799, 1299, FALSE, TRUE)
ON CONFLICT (subcategory) DO NOTHING;

-- ── RLS Policies ──────────────────────────────────────────────────────────
ALTER TABLE public.event_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_inquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_favourites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_provider_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_featured_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_monetization_config ENABLE ROW LEVEL SECURITY;

-- Public read for providers
CREATE POLICY "event_providers_public_read" ON public.event_providers FOR SELECT USING (TRUE);
CREATE POLICY "event_portfolio_public_read" ON public.event_portfolio FOR SELECT USING (TRUE);
CREATE POLICY "event_services_public_read" ON public.event_services FOR SELECT USING (TRUE);
CREATE POLICY "event_reviews_public_read" ON public.event_reviews FOR SELECT USING (TRUE);
CREATE POLICY "event_monetization_config_public_read" ON public.event_monetization_config FOR SELECT USING (TRUE);

-- Authenticated write for providers
CREATE POLICY "event_providers_auth_insert" ON public.event_providers FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "event_providers_auth_update" ON public.event_providers FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "event_portfolio_auth_insert" ON public.event_portfolio FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "event_services_auth_insert" ON public.event_services FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Inquiries
CREATE POLICY "event_inquiries_auth_insert" ON public.event_inquiries FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
CREATE POLICY "event_inquiries_auth_read" ON public.event_inquiries FOR SELECT USING (auth.uid() = customer_id OR auth.uid() IN (SELECT user_id FROM public.event_providers WHERE id = provider_id));

-- Favourites
CREATE POLICY "event_favourites_auth" ON public.event_favourites FOR ALL USING (auth.uid() = customer_id);

-- Reviews
CREATE POLICY "event_reviews_auth_insert" ON public.event_reviews FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Reports
CREATE POLICY "event_reports_auth_insert" ON public.event_reports FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Subscriptions
CREATE POLICY "event_subscriptions_auth_read" ON public.event_provider_subscriptions FOR SELECT USING (auth.uid() IN (SELECT user_id FROM public.event_providers WHERE id = provider_id));
CREATE POLICY "event_subscriptions_auth_insert" ON public.event_provider_subscriptions FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Featured
CREATE POLICY "event_featured_auth_read" ON public.event_featured_listings FOR SELECT USING (TRUE);
CREATE POLICY "event_featured_auth_insert" ON public.event_featured_listings FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);
