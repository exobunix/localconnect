-- ============================================================
-- Virtual Shop & Quotation System Migration
-- Timestamp: 20260705170000
-- ============================================================

-- ─── 1. Add missing Virtual Shop columns to service_providers ────────────────

ALTER TABLE public.service_providers
  ADD COLUMN IF NOT EXISTS services_offered TEXT[] DEFAULT ARRAY[]::TEXT[],
  ADD COLUMN IF NOT EXISTS starting_price NUMERIC DEFAULT 0,
  ADD COLUMN IF NOT EXISTS virtual_shop_completed BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS contact_number TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS map_location TEXT DEFAULT '';

-- ─── 2. Enquiries Table ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.enquiries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  title TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT '',
  subcategory TEXT DEFAULT '',
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status = ANY (ARRAY['pending','quoted','accepted','rejected','completed','cancelled'])),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_enquiries_customer_id ON public.enquiries(customer_id);
CREATE INDEX IF NOT EXISTS idx_enquiries_provider_id ON public.enquiries(provider_id);
CREATE INDEX IF NOT EXISTS idx_enquiries_status ON public.enquiries(status);

-- ─── 3. Quotations Table ─────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.quotations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  enquiry_id UUID NOT NULL REFERENCES public.enquiries(id) ON DELETE CASCADE,
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  customer_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,

  -- Line items stored as JSONB array
  line_items JSONB DEFAULT '[]'::JSONB,

  -- Itemized charges
  labour_charges NUMERIC DEFAULT 0,
  material_charges NUMERIC DEFAULT 0,
  visiting_charges NUMERIC DEFAULT 0,
  transportation_charges NUMERIC DEFAULT 0,
  equipment_charges NUMERIC DEFAULT 0,
  extra_charges NUMERIC DEFAULT 0,
  discount NUMERIC DEFAULT 0,
  tax_percentage NUMERIC DEFAULT 0,
  tax_amount NUMERIC DEFAULT 0,
  subtotal NUMERIC DEFAULT 0,
  total_amount NUMERIC DEFAULT 0,

  -- Meta
  expected_completion_time TEXT DEFAULT '',
  validity_days INTEGER DEFAULT 7,
  additional_notes TEXT DEFAULT '',
  terms_conditions TEXT DEFAULT '',

  -- Status
  status TEXT NOT NULL DEFAULT 'sent'
    CHECK (status = ANY (ARRAY['draft','sent','accepted','rejected','negotiating','expired'])),

  -- Template
  is_template BOOLEAN DEFAULT FALSE,
  template_name TEXT DEFAULT '',

  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_quotations_enquiry_id ON public.quotations(enquiry_id);
CREATE INDEX IF NOT EXISTS idx_quotations_provider_id ON public.quotations(provider_id);
CREATE INDEX IF NOT EXISTS idx_quotations_customer_id ON public.quotations(customer_id);
CREATE INDEX IF NOT EXISTS idx_quotations_status ON public.quotations(status);

-- ─── 4. Quotation Templates Table ────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.quotation_templates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  template_name TEXT NOT NULL DEFAULT '',
  category TEXT DEFAULT '',
  line_items JSONB DEFAULT '[]'::JSONB,
  labour_charges NUMERIC DEFAULT 0,
  material_charges NUMERIC DEFAULT 0,
  visiting_charges NUMERIC DEFAULT 0,
  transportation_charges NUMERIC DEFAULT 0,
  equipment_charges NUMERIC DEFAULT 0,
  extra_charges NUMERIC DEFAULT 0,
  discount NUMERIC DEFAULT 0,
  tax_percentage NUMERIC DEFAULT 0,
  additional_notes TEXT DEFAULT '',
  expected_completion_time TEXT DEFAULT '',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_quotation_templates_provider_id ON public.quotation_templates(provider_id);

-- ─── 5. Enable RLS ───────────────────────────────────────────────────────────

ALTER TABLE public.enquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quotations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quotation_templates ENABLE ROW LEVEL SECURITY;

-- ─── 6. RLS Policies ─────────────────────────────────────────────────────────

-- Enquiries: customers own their enquiries, providers can view/update theirs
DROP POLICY IF EXISTS "customers_manage_own_enquiries" ON public.enquiries;
CREATE POLICY "customers_manage_own_enquiries"
  ON public.enquiries FOR ALL TO authenticated
  USING (customer_id = auth.uid())
  WITH CHECK (customer_id = auth.uid());

DROP POLICY IF EXISTS "providers_view_their_enquiries" ON public.enquiries;
CREATE POLICY "providers_view_their_enquiries"
  ON public.enquiries FOR SELECT TO authenticated
  USING (
    provider_id IN (
      SELECT id FROM public.service_providers WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "providers_update_their_enquiries" ON public.enquiries;
CREATE POLICY "providers_update_their_enquiries"
  ON public.enquiries FOR UPDATE TO authenticated
  USING (
    provider_id IN (
      SELECT id FROM public.service_providers WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    provider_id IN (
      SELECT id FROM public.service_providers WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "admin_all_enquiries" ON public.enquiries;
CREATE POLICY "admin_all_enquiries"
  ON public.enquiries FOR ALL TO authenticated
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

-- Quotations: providers manage their quotations, customers can view/update status
DROP POLICY IF EXISTS "providers_manage_own_quotations" ON public.quotations;
CREATE POLICY "providers_manage_own_quotations"
  ON public.quotations FOR ALL TO authenticated
  USING (
    provider_id IN (
      SELECT id FROM public.service_providers WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    provider_id IN (
      SELECT id FROM public.service_providers WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "customers_view_own_quotations" ON public.quotations;
CREATE POLICY "customers_view_own_quotations"
  ON public.quotations FOR SELECT TO authenticated
  USING (customer_id = auth.uid());

DROP POLICY IF EXISTS "customers_update_quotation_status" ON public.quotations;
CREATE POLICY "customers_update_quotation_status"
  ON public.quotations FOR UPDATE TO authenticated
  USING (customer_id = auth.uid())
  WITH CHECK (customer_id = auth.uid());

DROP POLICY IF EXISTS "admin_all_quotations" ON public.quotations;
CREATE POLICY "admin_all_quotations"
  ON public.quotations FOR ALL TO authenticated
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

-- Quotation Templates: providers manage their own templates
DROP POLICY IF EXISTS "providers_manage_own_templates" ON public.quotation_templates;
CREATE POLICY "providers_manage_own_templates"
  ON public.quotation_templates FOR ALL TO authenticated
  USING (
    provider_id IN (
      SELECT id FROM public.service_providers WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    provider_id IN (
      SELECT id FROM public.service_providers WHERE user_id = auth.uid()
    )
  );

-- ─── 7. Updated_at trigger function ──────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS update_enquiries_updated_at ON public.enquiries;
CREATE TRIGGER update_enquiries_updated_at
  BEFORE UPDATE ON public.enquiries
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_quotations_updated_at ON public.quotations;
CREATE TRIGGER update_quotations_updated_at
  BEFORE UPDATE ON public.quotations
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

DROP TRIGGER IF EXISTS update_quotation_templates_updated_at ON public.quotation_templates;
CREATE TRIGGER update_quotation_templates_updated_at
  BEFORE UPDATE ON public.quotation_templates
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
