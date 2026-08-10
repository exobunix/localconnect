-- ============================================================
-- Grocery Lists (Previous Orders) + COD Payment Tracking
-- ============================================================

-- 1. GROCERY SAVED LISTS TABLE
-- Stores customer's saved/previous grocery lists for quick reorder
CREATE TABLE IF NOT EXISTS public.grocery_saved_lists (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  provider_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  shop_subcategory TEXT NOT NULL DEFAULT 'grocery',
  list_name TEXT NOT NULL DEFAULT 'My Grocery List',
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  total_items INTEGER NOT NULL DEFAULT 0,
  estimated_total DECIMAL(10,2) DEFAULT 0,
  source_order_id UUID REFERENCES public.shop_orders(id) ON DELETE SET NULL,
  is_active BOOLEAN DEFAULT true,
  last_ordered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 2. COD PAYMENT TRACKING TABLE
-- Tracks Cash on Delivery payment status across all shop subcategories
CREATE TABLE IF NOT EXISTS public.shop_cod_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID REFERENCES public.shop_orders(id) ON DELETE CASCADE UNIQUE,
  customer_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  provider_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  shop_subcategory TEXT NOT NULL,
  amount DECIMAL(10,2) NOT NULL DEFAULT 0,
  payment_status TEXT NOT NULL DEFAULT 'pending',
  -- pending | collected | disputed | waived
  collected_at TIMESTAMPTZ,
  collected_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. INDEXES
CREATE INDEX IF NOT EXISTS idx_grocery_lists_customer ON public.grocery_saved_lists(customer_id);
CREATE INDEX IF NOT EXISTS idx_grocery_lists_subcategory ON public.grocery_saved_lists(shop_subcategory);
CREATE INDEX IF NOT EXISTS idx_grocery_lists_active ON public.grocery_saved_lists(is_active);
CREATE INDEX IF NOT EXISTS idx_cod_payments_order ON public.shop_cod_payments(order_id);
CREATE INDEX IF NOT EXISTS idx_cod_payments_provider ON public.shop_cod_payments(provider_id);
CREATE INDEX IF NOT EXISTS idx_cod_payments_status ON public.shop_cod_payments(payment_status);

-- 4. ENABLE RLS
ALTER TABLE public.grocery_saved_lists ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_cod_payments ENABLE ROW LEVEL SECURITY;

-- 5. RLS POLICIES

-- grocery_saved_lists: customer manages own lists
DROP POLICY IF EXISTS "customer_manage_own_grocery_lists" ON public.grocery_saved_lists;
CREATE POLICY "customer_manage_own_grocery_lists" ON public.grocery_saved_lists
FOR ALL TO authenticated
USING (customer_id = auth.uid())
WITH CHECK (customer_id = auth.uid());

-- shop_cod_payments: customer read own, provider read/update own, admin full
DROP POLICY IF EXISTS "customer_read_own_cod" ON public.shop_cod_payments;
CREATE POLICY "customer_read_own_cod" ON public.shop_cod_payments
FOR SELECT TO authenticated
USING (customer_id = auth.uid());

DROP POLICY IF EXISTS "provider_manage_own_cod" ON public.shop_cod_payments;
CREATE POLICY "provider_manage_own_cod" ON public.shop_cod_payments
FOR ALL TO authenticated
USING (provider_id = auth.uid())
WITH CHECK (provider_id = auth.uid());

DROP POLICY IF EXISTS "admin_manage_all_cod" ON public.shop_cod_payments;
CREATE POLICY "admin_manage_all_cod" ON public.shop_cod_payments
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

-- 6. TRIGGER: auto-create COD record when order payment_method = 'cod'
CREATE OR REPLACE FUNCTION public.create_cod_record_on_order()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.payment_method = 'cod' THEN
    INSERT INTO public.shop_cod_payments (
      order_id, customer_id, provider_id, shop_subcategory, amount, payment_status
    ) VALUES (
      NEW.id, NEW.customer_id, NEW.provider_id,
      NEW.shop_subcategory::TEXT, NEW.total_amount, 'pending'
    )
    ON CONFLICT (order_id) DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_create_cod_on_order ON public.shop_orders;
CREATE TRIGGER trg_create_cod_on_order
AFTER INSERT ON public.shop_orders
FOR EACH ROW EXECUTE FUNCTION public.create_cod_record_on_order();

-- 7. TRIGGER: auto-save grocery list when order is placed
CREATE OR REPLACE FUNCTION public.save_grocery_list_on_order()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_item_count INTEGER;
BEGIN
  -- Only save for grocery/vegetables subcategories
  IF NEW.shop_subcategory::TEXT IN ('grocery', 'vegetables') THEN
    v_item_count := jsonb_array_length(NEW.items);
    INSERT INTO public.grocery_saved_lists (
      customer_id, provider_id, shop_subcategory,
      list_name, items, total_items, estimated_total,
      source_order_id, last_ordered_at
    ) VALUES (
      NEW.customer_id, NEW.provider_id, NEW.shop_subcategory::TEXT,
      'Order on ' || TO_CHAR(NEW.created_at, 'DD Mon YYYY'),
      NEW.items, v_item_count, NEW.subtotal,
      NEW.id, NEW.created_at
    );
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_save_grocery_list ON public.shop_orders;
CREATE TRIGGER trg_save_grocery_list
AFTER INSERT ON public.shop_orders
FOR EACH ROW EXECUTE FUNCTION public.save_grocery_list_on_order();

-- 8. UPDATE TRIGGER for updated_at
CREATE OR REPLACE FUNCTION public.update_grocery_list_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_grocery_list_updated_at ON public.grocery_saved_lists;
CREATE TRIGGER trg_grocery_list_updated_at
BEFORE UPDATE ON public.grocery_saved_lists
FOR EACH ROW EXECUTE FUNCTION public.update_grocery_list_updated_at();
