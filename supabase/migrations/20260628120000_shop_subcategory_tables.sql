-- ============================================================
-- Shop Subcategory Module: Products, Inventory, Orders
-- ============================================================

-- 1. ENUMS
DROP TYPE IF EXISTS public.shop_subcategory CASCADE;
CREATE TYPE public.shop_subcategory AS ENUM (
  'grocery', 'vegetables', 'electrical', 'plumbing_hardware',
  'meat_fish', 'seasonal', 'others_shop'
);

DROP TYPE IF EXISTS public.shop_order_status CASCADE;
CREATE TYPE public.shop_order_status AS ENUM (
  'pending', 'accepted', 'rejected', 'preparing',
  'out_for_delivery', 'delivered', 'cancelled'
);

DROP TYPE IF EXISTS public.delivery_type CASCADE;
CREATE TYPE public.delivery_type AS ENUM ('home_delivery', 'self_pickup', 'both');

DROP TYPE IF EXISTS public.meat_cut_type CASCADE;
CREATE TYPE public.meat_cut_type AS ENUM (
  'whole', 'cut_pieces', 'boneless', 'bone_in', 'minced', 'curry_cut', 'biryani_cut'
);

-- 2. SHOP PRODUCTS TABLE
CREATE TABLE IF NOT EXISTS public.shop_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  shop_subcategory public.shop_subcategory NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  category TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL DEFAULT 0,
  mrp DECIMAL(10,2),
  unit TEXT NOT NULL DEFAULT 'piece',
  stock_quantity INTEGER NOT NULL DEFAULT 0,
  min_order_qty INTEGER DEFAULT 1,
  max_order_qty INTEGER DEFAULT 100,
  is_available BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  images JSONB DEFAULT '[]'::jsonb,
  specifications JSONB DEFAULT '{}'::jsonb,
  tags TEXT[] DEFAULT ARRAY[]::TEXT[],
  discount_percent DECIMAL(5,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. MEAT PRODUCT OPTIONS (extends shop_products for meat/fish)
CREATE TABLE IF NOT EXISTS public.meat_product_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID REFERENCES public.shop_products(id) ON DELETE CASCADE,
  cut_type public.meat_cut_type NOT NULL,
  price_per_kg DECIMAL(10,2) NOT NULL,
  is_available BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 4. SHOP DELIVERY CONFIG
CREATE TABLE IF NOT EXISTS public.shop_delivery_config (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE UNIQUE,
  delivery_type public.delivery_type DEFAULT 'both',
  delivery_radius_km DECIMAL(5,2) DEFAULT 5.0,
  min_order_value DECIMAL(10,2) DEFAULT 0,
  delivery_charge DECIMAL(10,2) DEFAULT 0,
  free_delivery_above DECIMAL(10,2),
  business_hours JSONB DEFAULT '{}'::jsonb,
  delivery_slots JSONB DEFAULT '[]'::jsonb,
  is_cod_enabled BOOLEAN DEFAULT true,
  is_online_payment_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 5. SHOP ORDERS
CREATE TABLE IF NOT EXISTS public.shop_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  provider_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  shop_subcategory public.shop_subcategory NOT NULL,
  order_status public.shop_order_status DEFAULT 'pending',
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
  delivery_charge DECIMAL(10,2) DEFAULT 0,
  discount_amount DECIMAL(10,2) DEFAULT 0,
  total_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  delivery_type public.delivery_type DEFAULT 'home_delivery',
  delivery_address JSONB,
  delivery_slot TEXT,
  delivery_date DATE,
  payment_method TEXT DEFAULT 'cod',
  payment_status TEXT DEFAULT 'pending',
  special_instructions TEXT,
  shopping_list_image TEXT,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 6. SHOP ORDER TRACKING
CREATE TABLE IF NOT EXISTS public.shop_order_tracking (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.shop_orders(id) ON DELETE CASCADE,
  status public.shop_order_status NOT NULL,
  message TEXT,
  updated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 7. SEASONAL CATEGORY CONFIG (admin controlled)
CREATE TABLE IF NOT EXISTS public.seasonal_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  icon TEXT,
  is_active BOOLEAN DEFAULT false,
  start_date DATE,
  end_date DATE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 8. INDEXES
CREATE INDEX IF NOT EXISTS idx_shop_products_provider ON public.shop_products(provider_id);
CREATE INDEX IF NOT EXISTS idx_shop_products_subcategory ON public.shop_products(shop_subcategory);
CREATE INDEX IF NOT EXISTS idx_shop_products_available ON public.shop_products(is_available);
CREATE INDEX IF NOT EXISTS idx_shop_orders_customer ON public.shop_orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_shop_orders_provider ON public.shop_orders(provider_id);
CREATE INDEX IF NOT EXISTS idx_shop_orders_status ON public.shop_orders(order_status);
CREATE INDEX IF NOT EXISTS idx_shop_order_tracking_order ON public.shop_order_tracking(order_id);
CREATE INDEX IF NOT EXISTS idx_meat_options_product ON public.meat_product_options(product_id);

-- 9. FUNCTIONS
CREATE OR REPLACE FUNCTION public.update_shop_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

-- 10. ENABLE RLS
ALTER TABLE public.shop_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meat_product_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_delivery_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_order_tracking ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.seasonal_categories ENABLE ROW LEVEL SECURITY;

-- 11. RLS POLICIES

-- shop_products: public read, provider write own
DROP POLICY IF EXISTS "public_read_shop_products" ON public.shop_products;
CREATE POLICY "public_read_shop_products" ON public.shop_products
FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "provider_manage_own_products" ON public.shop_products;
CREATE POLICY "provider_manage_own_products" ON public.shop_products
FOR ALL TO authenticated
USING (provider_id = auth.uid())
WITH CHECK (provider_id = auth.uid());

-- meat_product_options: public read, provider write
DROP POLICY IF EXISTS "public_read_meat_options" ON public.meat_product_options;
CREATE POLICY "public_read_meat_options" ON public.meat_product_options
FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "provider_manage_meat_options" ON public.meat_product_options;
CREATE POLICY "provider_manage_meat_options" ON public.meat_product_options
FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.shop_products sp
    WHERE sp.id = product_id AND sp.provider_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.shop_products sp
    WHERE sp.id = product_id AND sp.provider_id = auth.uid()
  )
);

-- shop_delivery_config: public read, provider write own
DROP POLICY IF EXISTS "public_read_delivery_config" ON public.shop_delivery_config;
CREATE POLICY "public_read_delivery_config" ON public.shop_delivery_config
FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "provider_manage_delivery_config" ON public.shop_delivery_config;
CREATE POLICY "provider_manage_delivery_config" ON public.shop_delivery_config
FOR ALL TO authenticated
USING (provider_id = auth.uid())
WITH CHECK (provider_id = auth.uid());

-- shop_orders: customer and provider access
DROP POLICY IF EXISTS "customer_manage_own_shop_orders" ON public.shop_orders;
CREATE POLICY "customer_manage_own_shop_orders" ON public.shop_orders
FOR ALL TO authenticated
USING (customer_id = auth.uid())
WITH CHECK (customer_id = auth.uid());

DROP POLICY IF EXISTS "provider_view_own_shop_orders" ON public.shop_orders;
CREATE POLICY "provider_view_own_shop_orders" ON public.shop_orders
FOR SELECT TO authenticated
USING (provider_id = auth.uid());

DROP POLICY IF EXISTS "provider_update_own_shop_orders" ON public.shop_orders;
CREATE POLICY "provider_update_own_shop_orders" ON public.shop_orders
FOR UPDATE TO authenticated
USING (provider_id = auth.uid())
WITH CHECK (provider_id = auth.uid());

-- shop_order_tracking: authenticated read
DROP POLICY IF EXISTS "authenticated_read_shop_tracking" ON public.shop_order_tracking;
CREATE POLICY "authenticated_read_shop_tracking" ON public.shop_order_tracking
FOR SELECT TO authenticated USING (true);

DROP POLICY IF EXISTS "provider_insert_shop_tracking" ON public.shop_order_tracking;
CREATE POLICY "provider_insert_shop_tracking" ON public.shop_order_tracking
FOR INSERT TO authenticated
WITH CHECK (updated_by = auth.uid());

-- seasonal_categories: public read
DROP POLICY IF EXISTS "public_read_seasonal_categories" ON public.seasonal_categories;
CREATE POLICY "public_read_seasonal_categories" ON public.seasonal_categories
FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "admin_manage_seasonal_categories" ON public.seasonal_categories;
CREATE POLICY "admin_manage_seasonal_categories" ON public.seasonal_categories
FOR ALL TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() AND up.role = 'admin'
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.user_profiles up
    WHERE up.id = auth.uid() AND up.role = 'admin'
  )
);

-- 12. TRIGGERS
DROP TRIGGER IF EXISTS trg_shop_products_updated_at ON public.shop_products;
CREATE TRIGGER trg_shop_products_updated_at
BEFORE UPDATE ON public.shop_products
FOR EACH ROW EXECUTE FUNCTION public.update_shop_updated_at();

DROP TRIGGER IF EXISTS trg_shop_delivery_config_updated_at ON public.shop_delivery_config;
CREATE TRIGGER trg_shop_delivery_config_updated_at
BEFORE UPDATE ON public.shop_delivery_config
FOR EACH ROW EXECUTE FUNCTION public.update_shop_updated_at();

DROP TRIGGER IF EXISTS trg_shop_orders_updated_at ON public.shop_orders;
CREATE TRIGGER trg_shop_orders_updated_at
BEFORE UPDATE ON public.shop_orders
FOR EACH ROW EXECUTE FUNCTION public.update_shop_updated_at();

-- 13. SEED SEASONAL CATEGORIES
DO $$
BEGIN
  INSERT INTO public.seasonal_categories (name, description, icon, is_active, start_date, end_date)
  VALUES
    ('Diwali Decorations', 'Lights, diyas, rangoli, and festive decor', 'celebration', false, null, null),
    ('Holi Colours', 'Gulal, water colours, pichkari, and accessories', 'palette', false, null, null),
    ('Ganesh Festival', 'Idols, decorations, puja items', 'temple_hindu', false, null, null),
    ('Mango Season', 'Fresh mangoes - Alphonso, Kesar, Dasheri', 'local_florist', false, null, null),
    ('Monsoon Essentials', 'Umbrellas, raincoats, waterproof items', 'umbrella', false, null, null),
    ('Winter Products', 'Woollens, heaters, blankets', 'ac_unit', false, null, null),
    ('School Supplies', 'Books, stationery, bags, uniforms', 'school', false, null, null),
    ('Christmas', 'Trees, decorations, gifts, lights', 'star', false, null, null)
  ON CONFLICT DO NOTHING;
END $$;
