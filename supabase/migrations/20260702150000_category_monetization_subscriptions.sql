-- ─────────────────────────────────────────────────────────────────────────────
-- Category Monetization Config + Server-Side Subscription Enforcement
-- Migration: 20260702150000_category_monetization_subscriptions
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Category Monetization Config Table ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.category_monetization_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  -- Scope: which category/subcategory this rule applies to
  category TEXT NOT NULL,          -- e.g. 'home_maintenance', 'shop', 'rent', 'event'
  subcategory TEXT NOT NULL,       -- e.g. 'plumber', 'vegetables', 'room', 'photography'
  -- Monetization model
  monetization_model TEXT NOT NULL DEFAULT 'subscription'
    CHECK (monetization_model IN ('free','subscription','pay_per_listing','pay_per_lead','hybrid')),
  -- Free tier
  free_listings_allowed INTEGER NOT NULL DEFAULT 3,  -- -1 = unlimited
  -- Subscription pricing (monthly)
  basic_plan_price NUMERIC(10,2) NOT NULL DEFAULT 0,
  standard_plan_price NUMERIC(10,2) NOT NULL DEFAULT 299,
  premium_plan_price NUMERIC(10,2) NOT NULL DEFAULT 599,
  -- Listing limits per plan (-1 = unlimited)
  free_plan_listings INTEGER NOT NULL DEFAULT 3,
  basic_plan_listings INTEGER NOT NULL DEFAULT 10,
  standard_plan_listings INTEGER NOT NULL DEFAULT 50,
  premium_plan_listings INTEGER NOT NULL DEFAULT -1,
  -- Pay-per-listing
  pay_per_listing_price NUMERIC(10,2) NOT NULL DEFAULT 49,
  pay_per_listing_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  -- Pay-per-lead
  pay_per_lead_price NUMERIC(10,2) NOT NULL DEFAULT 29,
  pay_per_lead_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  -- Featured listing charges
  featured_7day_price NUMERIC(10,2) NOT NULL DEFAULT 149,
  featured_15day_price NUMERIC(10,2) NOT NULL DEFAULT 299,
  featured_30day_price NUMERIC(10,2) NOT NULL DEFAULT 499,
  featured_listing_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  -- Sponsored listing charges
  sponsored_listing_price NUMERIC(10,2) NOT NULL DEFAULT 399,
  sponsored_listing_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  -- Verified badge charges
  verified_badge_price NUMERIC(10,2) NOT NULL DEFAULT 999,
  verified_badge_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  -- Display settings
  featured_count_displayed INTEGER NOT NULL DEFAULT 5,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (category, subcategory)
);

-- ── 2. Indexes ────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_cat_monetization_category ON public.category_monetization_config(category);
CREATE INDEX IF NOT EXISTS idx_cat_monetization_subcategory ON public.category_monetization_config(subcategory);
CREATE INDEX IF NOT EXISTS idx_cat_monetization_model ON public.category_monetization_config(monetization_model);

-- ── 3. Server-Side Subscription Enforcement Functions ────────────────────────

-- 3a. Check if a provider has an active subscription
CREATE OR REPLACE FUNCTION public.provider_has_active_subscription(p_provider_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.provider_subscriptions
    WHERE provider_id = p_provider_id
      AND status = 'active'
      AND expires_at > NOW()
  );
$$;

-- 3b. Get the active subscription plan name for a provider
CREATE OR REPLACE FUNCTION public.provider_active_plan(p_provider_id UUID)
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT COALESCE(
    (SELECT sp.name
     FROM public.provider_subscriptions ps
     JOIN public.subscription_plans sp ON ps.plan_id = sp.id
     WHERE ps.provider_id = p_provider_id
       AND ps.status = 'active'
       AND ps.expires_at > NOW()
     ORDER BY ps.expires_at DESC
     LIMIT 1),
    'Free'
  );
$$;

-- 3c. Get listing limit for a provider in a given category/subcategory
CREATE OR REPLACE FUNCTION public.provider_listing_limit(
  p_provider_id UUID,
  p_category TEXT,
  p_subcategory TEXT
)
RETURNS INTEGER
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_plan_name TEXT;
  v_limit INTEGER;
BEGIN
  v_plan_name := public.provider_active_plan(p_provider_id);

  SELECT
    CASE LOWER(v_plan_name)
      WHEN 'basic'    THEN cmc.basic_plan_listings
      WHEN 'pro'      THEN cmc.standard_plan_listings
      WHEN 'premium'  THEN cmc.premium_plan_listings
      ELSE cmc.free_plan_listings
    END
  INTO v_limit
  FROM public.category_monetization_config cmc
  WHERE cmc.category = p_category
    AND cmc.subcategory = p_subcategory
    AND cmc.is_active = TRUE
  LIMIT 1;

  RETURN COALESCE(v_limit, 3); -- default 3 if no config found
END;
$$;

-- 3d. Check if a provider can create a new listing (server-side gate)
CREATE OR REPLACE FUNCTION public.provider_can_create_listing(
  p_provider_id UUID,
  p_category TEXT,
  p_subcategory TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_limit INTEGER;
  v_current_count INTEGER;
  v_plan_name TEXT;
  v_model TEXT;
BEGIN
  v_plan_name := public.provider_active_plan(p_provider_id);
  v_limit := public.provider_listing_limit(p_provider_id, p_category, p_subcategory);

  -- Get monetization model
  SELECT monetization_model INTO v_model
  FROM public.category_monetization_config
  WHERE category = p_category AND subcategory = p_subcategory AND is_active = TRUE
  LIMIT 1;

  -- Count current active listings for this provider in this subcategory
  SELECT COUNT(*) INTO v_current_count
  FROM public.service_providers
  WHERE user_id = (
    SELECT user_id FROM public.service_providers WHERE id = p_provider_id LIMIT 1
  )
  AND category = p_category
  AND is_active = TRUE;

  -- -1 means unlimited
  IF v_limit = -1 THEN
    RETURN jsonb_build_object(
      'allowed', TRUE,
      'plan', v_plan_name,
      'current_count', v_current_count,
      'limit', -1,
      'model', COALESCE(v_model, 'subscription')
    );
  END IF;

  IF v_current_count < v_limit THEN
    RETURN jsonb_build_object(
      'allowed', TRUE,
      'plan', v_plan_name,
      'current_count', v_current_count,
      'limit', v_limit,
      'model', COALESCE(v_model, 'subscription')
    );
  ELSE
    RETURN jsonb_build_object(
      'allowed', FALSE,
      'plan', v_plan_name,
      'current_count', v_current_count,
      'limit', v_limit,
      'model', COALESCE(v_model, 'subscription'),
      'reason', 'Listing limit reached for your current plan. Please upgrade to add more listings.'
    );
  END IF;
END;
$$;

-- 3e. Auto-expire subscriptions that have passed their expiry date
CREATE OR REPLACE FUNCTION public.expire_stale_subscriptions()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  UPDATE public.provider_subscriptions
  SET status = 'expired'
  WHERE status = 'active'
    AND expires_at < NOW();

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- 3f. Trigger function: auto-expire on subscription read (lazy expiry)
CREATE OR REPLACE FUNCTION public.check_subscription_expiry()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.expires_at < NOW() AND NEW.status = 'active' THEN
    NEW.status := 'expired';
  END IF;
  RETURN NEW;
END;
$$;

-- 3g. Updated_at trigger for monetization config
CREATE OR REPLACE FUNCTION public.update_cat_monetization_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

-- ── 4. Triggers ───────────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS trg_cat_monetization_updated_at ON public.category_monetization_config;
CREATE TRIGGER trg_cat_monetization_updated_at
  BEFORE UPDATE ON public.category_monetization_config
  FOR EACH ROW EXECUTE FUNCTION public.update_cat_monetization_updated_at();

-- Lazy expiry on subscription update
DROP TRIGGER IF EXISTS trg_subscription_expiry_check ON public.provider_subscriptions;
CREATE TRIGGER trg_subscription_expiry_check
  BEFORE UPDATE ON public.provider_subscriptions
  FOR EACH ROW EXECUTE FUNCTION public.check_subscription_expiry();

-- ── 5. RLS ────────────────────────────────────────────────────────────────────
ALTER TABLE public.category_monetization_config ENABLE ROW LEVEL SECURITY;

-- Public read (providers and customers can read pricing rules)
DROP POLICY IF EXISTS "cat_monetization_public_read" ON public.category_monetization_config;
CREATE POLICY "cat_monetization_public_read"
  ON public.category_monetization_config FOR SELECT
  USING (TRUE);

-- Admin full access (using auth metadata to avoid recursion)
DROP POLICY IF EXISTS "cat_monetization_admin_all" ON public.category_monetization_config;
CREATE POLICY "cat_monetization_admin_all"
  ON public.category_monetization_config FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM auth.users au
      WHERE au.id = auth.uid()
        AND (au.raw_user_meta_data->>'role' = 'admin'
             OR au.raw_app_meta_data->>'role' = 'admin')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM auth.users au
      WHERE au.id = auth.uid()
        AND (au.raw_user_meta_data->>'role' = 'admin'
             OR au.raw_app_meta_data->>'role' = 'admin')
    )
  );

-- ── 6. Seed Default Config for All Major Categories ───────────────────────────
INSERT INTO public.category_monetization_config
  (category, subcategory, monetization_model,
   free_listings_allowed, free_plan_listings,
   basic_plan_price, standard_plan_price, premium_plan_price,
   basic_plan_listings, standard_plan_listings, premium_plan_listings,
   pay_per_listing_price, pay_per_listing_enabled,
   pay_per_lead_price, pay_per_lead_enabled,
   featured_7day_price, featured_15day_price, featured_30day_price,
   sponsored_listing_price, verified_badge_price,
   featured_listing_enabled, sponsored_listing_enabled, verified_badge_enabled)
VALUES
  -- Home Maintenance
  ('home_maintenance','plumber','subscription',2,2,0,299,599,5,30,-1,49,FALSE,29,FALSE,149,299,499,399,999,TRUE,TRUE,TRUE),
  ('home_maintenance','electrician','subscription',2,2,0,299,599,5,30,-1,49,FALSE,29,FALSE,149,299,499,399,999,TRUE,TRUE,TRUE),
  ('home_maintenance','painter','subscription',2,2,0,249,499,5,25,-1,39,FALSE,25,FALSE,129,249,399,349,799,TRUE,TRUE,FALSE),
  ('home_maintenance','mason','subscription',2,2,0,249,499,5,25,-1,39,FALSE,25,FALSE,129,249,399,349,799,TRUE,TRUE,FALSE),
  ('home_maintenance','carpenter','subscription',2,2,0,299,599,5,30,-1,49,FALSE,29,FALSE,149,299,499,399,999,TRUE,TRUE,TRUE),
  ('home_maintenance','cleaning','hybrid',3,3,0,199,399,8,40,-1,29,TRUE,19,TRUE,99,199,349,299,699,TRUE,TRUE,FALSE),
  ('home_maintenance','daily_wage','hybrid',3,3,0,149,299,10,50,-1,19,TRUE,15,TRUE,79,149,249,249,499,FALSE,FALSE,FALSE),
  -- Shop
  ('shop','vegetables','free',10,10,0,0,0,-1,-1,-1,0,FALSE,0,FALSE,99,199,349,299,499,TRUE,FALSE,FALSE),
  ('shop','meat','subscription',3,3,0,199,399,15,60,-1,29,FALSE,19,FALSE,99,199,349,299,699,TRUE,TRUE,FALSE),
  ('shop','electrical_hardware','subscription',5,5,0,299,599,20,80,-1,39,FALSE,25,FALSE,149,299,499,399,999,TRUE,TRUE,TRUE),
  ('shop','plumbing_hardware','subscription',5,5,0,299,599,20,80,-1,39,FALSE,25,FALSE,149,299,499,399,999,TRUE,TRUE,TRUE),
  ('shop','seasonal','free',20,20,0,0,0,-1,-1,-1,0,FALSE,0,FALSE,79,149,249,199,399,TRUE,FALSE,FALSE),
  -- Rent
  ('rent','room','subscription',2,2,0,299,599,5,20,-1,99,FALSE,49,FALSE,199,399,699,499,1499,TRUE,TRUE,TRUE),
  ('rent','pg','subscription',2,2,0,399,799,5,20,-1,149,FALSE,69,FALSE,249,499,899,599,1999,TRUE,TRUE,TRUE),
  ('rent','hostel','subscription',2,2,0,399,799,5,20,-1,149,FALSE,69,FALSE,249,499,899,599,1999,TRUE,TRUE,TRUE),
  ('rent','villa','subscription',1,1,0,499,999,3,10,-1,199,FALSE,99,FALSE,299,599,999,799,2499,TRUE,TRUE,TRUE),
  ('rent','tools','hybrid',5,5,0,199,399,15,60,-1,29,TRUE,19,TRUE,99,199,349,299,699,TRUE,FALSE,FALSE),
  -- Event
  ('event','photography','subscription',1,1,0,299,599,3,15,-1,149,FALSE,79,FALSE,199,399,699,499,1499,TRUE,TRUE,TRUE),
  ('event','catering','subscription',1,1,0,499,999,3,15,-1,199,FALSE,99,FALSE,249,499,899,699,1999,TRUE,TRUE,TRUE),
  ('event','makeup','hybrid',2,2,0,199,399,5,25,-1,79,TRUE,49,TRUE,149,299,499,399,999,TRUE,TRUE,FALSE),
  ('event','mehendi','hybrid',2,2,0,149,299,5,25,-1,59,TRUE,39,TRUE,99,199,349,299,799,TRUE,FALSE,FALSE),
  ('event','sound','subscription',1,1,0,249,499,3,15,-1,99,FALSE,59,FALSE,149,299,499,399,999,TRUE,TRUE,FALSE),
  ('event','decoration','subscription',1,1,0,399,799,3,15,-1,149,FALSE,79,FALSE,199,399,699,499,1499,TRUE,TRUE,TRUE),
  -- Transport
  ('transport','ride','subscription',1,1,0,199,399,5,20,-1,49,FALSE,29,FALSE,99,199,349,299,699,TRUE,TRUE,TRUE),
  ('transport','goods','subscription',1,1,0,299,599,5,20,-1,79,FALSE,49,FALSE,149,299,499,399,999,TRUE,TRUE,TRUE)
ON CONFLICT (category, subcategory) DO NOTHING;
