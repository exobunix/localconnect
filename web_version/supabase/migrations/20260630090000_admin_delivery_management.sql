-- Admin Delivery Management Tables
-- delivery_vendors, pricing_tiers, commission_rules

-- ── 1. DELIVERY VENDORS ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.delivery_vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL DEFAULT '',
  city TEXT NOT NULL DEFAULT '',
  contact_name TEXT NOT NULL DEFAULT '',
  phone TEXT NOT NULL DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('active', 'pending', 'suspended')),
  rating NUMERIC DEFAULT 0.0,
  total_riders INTEGER DEFAULT 0,
  completed_today INTEGER DEFAULT 0,
  revenue_today NUMERIC DEFAULT 0,
  commission_today NUMERIC DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_delivery_vendors_status ON public.delivery_vendors(status);
CREATE INDEX IF NOT EXISTS idx_delivery_vendors_city ON public.delivery_vendors(city);

ALTER TABLE public.delivery_vendors ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_full_access_delivery_vendors" ON public.delivery_vendors;
CREATE POLICY "admin_full_access_delivery_vendors"
ON public.delivery_vendors FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

DROP POLICY IF EXISTS "public_read_delivery_vendors" ON public.delivery_vendors;
CREATE POLICY "public_read_delivery_vendors"
ON public.delivery_vendors FOR SELECT TO authenticated
USING (true);

-- ── 2. DELIVERY RIDERS ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.delivery_riders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  vendor_id UUID REFERENCES public.delivery_vendors(id) ON DELETE SET NULL,
  name TEXT NOT NULL DEFAULT '',
  city TEXT NOT NULL DEFAULT '',
  vehicle TEXT NOT NULL DEFAULT 'Bike',
  status TEXT NOT NULL DEFAULT 'offline' CHECK (status IN ('online', 'on_delivery', 'offline')),
  deliveries_today INTEGER DEFAULT 0,
  rating NUMERIC DEFAULT 0.0,
  earnings_today NUMERIC DEFAULT 0,
  lat NUMERIC DEFAULT 18.5204,
  lng NUMERIC DEFAULT 73.8567,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_delivery_riders_vendor_id ON public.delivery_riders(vendor_id);
CREATE INDEX IF NOT EXISTS idx_delivery_riders_status ON public.delivery_riders(status);
CREATE INDEX IF NOT EXISTS idx_delivery_riders_city ON public.delivery_riders(city);

ALTER TABLE public.delivery_riders ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_full_access_delivery_riders" ON public.delivery_riders;
CREATE POLICY "admin_full_access_delivery_riders"
ON public.delivery_riders FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

DROP POLICY IF EXISTS "public_read_delivery_riders" ON public.delivery_riders;
CREATE POLICY "public_read_delivery_riders"
ON public.delivery_riders FOR SELECT TO authenticated
USING (true);

-- ── 3. PRICING TIERS ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.delivery_pricing_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL DEFAULT '',
  base_charge NUMERIC NOT NULL DEFAULT 0,
  per_km_rate NUMERIC NOT NULL DEFAULT 0,
  weight_charge NUMERIC NOT NULL DEFAULT 0,
  max_weight NUMERIC NOT NULL DEFAULT 5,
  color_hex TEXT NOT NULL DEFAULT '#1565C0',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.delivery_pricing_tiers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_full_access_pricing_tiers" ON public.delivery_pricing_tiers;
CREATE POLICY "admin_full_access_pricing_tiers"
ON public.delivery_pricing_tiers FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

DROP POLICY IF EXISTS "public_read_pricing_tiers" ON public.delivery_pricing_tiers;
CREATE POLICY "public_read_pricing_tiers"
ON public.delivery_pricing_tiers FOR SELECT TO authenticated
USING (true);

-- ── 4. COMMISSION RULES ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.delivery_commission_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL DEFAULT '',
  type TEXT NOT NULL DEFAULT 'percentage' CHECK (type IN ('percentage', 'flat')),
  value NUMERIC NOT NULL DEFAULT 0,
  applies_to TEXT NOT NULL DEFAULT 'All Vendors',
  min_orders INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.delivery_commission_rules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_full_access_commission_rules" ON public.delivery_commission_rules;
CREATE POLICY "admin_full_access_commission_rules"
ON public.delivery_commission_rules FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

DROP POLICY IF EXISTS "public_read_commission_rules" ON public.delivery_commission_rules;
CREATE POLICY "public_read_commission_rules"
ON public.delivery_commission_rules FOR SELECT TO authenticated
USING (true);

-- ── 5. DELIVERY SURCHARGES ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.delivery_surcharges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  peak_hour INTEGER DEFAULT 15,
  night_charge INTEGER DEFAULT 20,
  rain_surcharge INTEGER DEFAULT 10,
  holiday_surcharge INTEGER DEFAULT 25,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.delivery_surcharges ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "admin_full_access_delivery_surcharges" ON public.delivery_surcharges;
CREATE POLICY "admin_full_access_delivery_surcharges"
ON public.delivery_surcharges FOR ALL TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

DROP POLICY IF EXISTS "public_read_delivery_surcharges" ON public.delivery_surcharges;
CREATE POLICY "public_read_delivery_surcharges"
ON public.delivery_surcharges FOR SELECT TO authenticated
USING (true);

-- ── 6. SEED DATA ─────────────────────────────────────────────────────────
DO $$
DECLARE
  v1 UUID := gen_random_uuid();
  v2 UUID := gen_random_uuid();
  v3 UUID := gen_random_uuid();
  v4 UUID := gen_random_uuid();
  v5 UUID := gen_random_uuid();
BEGIN
  -- Vendors
  INSERT INTO public.delivery_vendors (id, name, city, contact_name, phone, status, rating, total_riders, completed_today, revenue_today, commission_today)
  VALUES
    (v1, 'SpeedX Delivery Pune', 'Pune', 'Rahul Sharma', '+91 98765 43210', 'active', 4.7, 12, 85, 12500, 1250),
    (v2, 'City Runners Mumbai', 'Mumbai', 'Priya Mehta', '+91 87654 32109', 'active', 4.5, 28, 210, 38000, 3800),
    (v3, 'QuickDrop Nashik', 'Nashik', 'Amit Patil', '+91 76543 21098', 'pending', 0.0, 6, 0, 0, 0),
    (v4, 'Flash Delivery Nagpur', 'Nagpur', 'Suresh Yadav', '+91 65432 10987', 'suspended', 3.2, 9, 0, 0, 0),
    (v5, 'Bolt Express Aurangabad', 'Aurangabad', 'Neha Kulkarni', '+91 54321 09876', 'active', 4.3, 5, 42, 6300, 630)
  ON CONFLICT (id) DO NOTHING;

  -- Riders
  INSERT INTO public.delivery_riders (id, vendor_id, name, city, vehicle, status, deliveries_today, rating, earnings_today, lat, lng)
  VALUES
    (gen_random_uuid(), v1, 'Arjun Desai', 'Pune', 'Bike', 'online', 14, 4.8, 840, 18.5204, 73.8567),
    (gen_random_uuid(), v2, 'Kavya Nair', 'Mumbai', 'Scooter', 'on_delivery', 22, 4.9, 1320, 19.0760, 72.8777),
    (gen_random_uuid(), v1, 'Rohit Joshi', 'Pune', 'Bike', 'offline', 8, 4.2, 480, 18.5314, 73.8446),
    (gen_random_uuid(), v2, 'Sneha Pawar', 'Mumbai', 'Cycle', 'online', 18, 4.6, 1080, 19.0822, 72.8905),
    (gen_random_uuid(), v5, 'Vikram Singh', 'Aurangabad', 'Bike', 'on_delivery', 11, 4.5, 660, 19.8762, 75.3433),
    (gen_random_uuid(), v2, 'Pooja Shinde', 'Mumbai', 'Scooter', 'online', 25, 4.9, 1500, 19.0596, 72.8295),
    (gen_random_uuid(), v4, 'Manish Gupta', 'Nagpur', 'Bike', 'offline', 0, 3.8, 0, 21.1458, 79.0882)
  ON CONFLICT (id) DO NOTHING;

  -- Pricing Tiers
  INSERT INTO public.delivery_pricing_tiers (id, name, base_charge, per_km_rate, weight_charge, max_weight, color_hex, is_active)
  VALUES
    (gen_random_uuid(), 'Standard', 25, 8, 10, 5, '#1565C0', true),
    (gen_random_uuid(), 'Express', 55, 14, 15, 10, '#FF6B35', true),
    (gen_random_uuid(), 'Economy', 15, 5, 8, 3, '#2ECC71', true),
    (gen_random_uuid(), 'Bulk / Cargo', 80, 20, 5, 50, '#9B59B6', false)
  ON CONFLICT (id) DO NOTHING;

  -- Commission Rules
  INSERT INTO public.delivery_commission_rules (id, name, type, value, applies_to, min_orders, is_active)
  VALUES
    (gen_random_uuid(), 'Standard Commission', 'percentage', 10.0, 'All Vendors', 0, true),
    (gen_random_uuid(), 'High Volume Discount', 'percentage', 8.0, 'Vendors with 200+ orders/month', 200, true),
    (gen_random_uuid(), 'New Vendor Promo', 'percentage', 5.0, 'First 3 months', 0, true),
    (gen_random_uuid(), 'Express Delivery Fee', 'flat', 30.0, 'Express tier orders', 0, true),
    (gen_random_uuid(), 'Surge Commission', 'percentage', 12.0, 'Peak hours (6-9 PM)', 0, false)
  ON CONFLICT (id) DO NOTHING;

  -- Surcharges (single row config)
  INSERT INTO public.delivery_surcharges (id, peak_hour, night_charge, rain_surcharge, holiday_surcharge)
  VALUES (gen_random_uuid(), 15, 20, 10, 25)
  ON CONFLICT (id) DO NOTHING;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Seed data insertion failed: %', SQLERRM;
END $$;
