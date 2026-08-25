-- ─── COMPLAINTS TABLE ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.complaints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  complaint_number TEXT NOT NULL UNIQUE,
  customer_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  customer_name TEXT NOT NULL DEFAULT '',
  provider_id UUID REFERENCES public.service_providers(id) ON DELETE SET NULL,
  provider_name TEXT NOT NULL DEFAULT '',
  order_id UUID REFERENCES public.orders(id) ON DELETE SET NULL,
  issue TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high')),
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_review', 'resolved', 'closed')),
  admin_note TEXT DEFAULT '',
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.complaints ENABLE ROW LEVEL SECURITY;

-- Admin can do everything
CREATE POLICY "Admin full access complaints" ON public.complaints
  FOR ALL
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

-- Customers can insert their own complaints
CREATE POLICY "Customers can create complaints" ON public.complaints
  FOR INSERT
  WITH CHECK (auth.uid() = customer_id);

-- Customers can view their own complaints
CREATE POLICY "Customers can view own complaints" ON public.complaints
  FOR SELECT
  USING (auth.uid() = customer_id);

-- ─── CATEGORIES TABLE ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  name_marathi TEXT DEFAULT '',
  icon_name TEXT DEFAULT 'category',
  color_hex TEXT DEFAULT '#78909C',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.subcategories (
  id TEXT PRIMARY KEY,
  category_id TEXT NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_marathi TEXT DEFAULT '',
  icon_name TEXT DEFAULT 'label',
  sort_order INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subcategories ENABLE ROW LEVEL SECURITY;

-- Public read
CREATE POLICY "Public read categories" ON public.categories FOR SELECT USING (TRUE);
CREATE POLICY "Public read subcategories" ON public.subcategories FOR SELECT USING (TRUE);

-- Admin write
CREATE POLICY "Admin write categories" ON public.categories
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Admin write subcategories" ON public.subcategories
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ─── BANNER ADS TABLE ─────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.banner_ads (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  subtitle TEXT DEFAULT '',
  image_url TEXT DEFAULT '',
  action_url TEXT DEFAULT '',
  gradient_start TEXT DEFAULT '#1565C0',
  gradient_end TEXT DEFAULT '#1E88E5',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INT DEFAULT 0,
  starts_at TIMESTAMPTZ,
  ends_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.banner_ads ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read active banners" ON public.banner_ads
  FOR SELECT USING (is_active = TRUE);

CREATE POLICY "Admin full access banners" ON public.banner_ads
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.user_profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- Seed some sample banner ads
INSERT INTO public.banner_ads (title, subtitle, gradient_start, gradient_end, is_active, sort_order)
VALUES
  ('Summer Sale', 'Up to 50% off on all services', '#1565C0', '#42A5F5', TRUE, 1),
  ('New Providers', 'Discover top-rated local experts', '#6A1B9A', '#AB47BC', TRUE, 2),
  ('Refer & Earn', 'Get ₹100 for every referral', '#2E7D32', '#66BB6A', TRUE, 3)
ON CONFLICT DO NOTHING;
