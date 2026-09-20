-- Migration: 20260921000001_fix_reviews_categories_and_locations.sql
-- Description:
--   1. Ensures reviews table order_id is nullable (so providers can be reviewed directly).
--   2. Ensures reviews table RLS permits public reading and authenticated insertion.
--   3. Auto-sync trigger for provider rating and review_count on reviews insert/update/delete.
--   4. Adds subcategories columns (is_active, sort_order, updated_at, image_url, description) if missing.
--   5. Adds robust SECURITY DEFINER RPC functions for admin category & subcategory management.
--   6. Ensures service_providers has location coordinates and address fields.

-- ── 1. Reviews table fixes ──────────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'reviews') THEN
    -- Make order_id nullable if it wasn't
    ALTER TABLE public.reviews ALTER COLUMN order_id DROP NOT NULL;
    
    -- Ensure columns exist
    ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS customer_id UUID REFERENCES public.user_profiles(id);
    ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS provider_id UUID;
    ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS provider_name TEXT DEFAULT '';
    ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS service TEXT DEFAULT '';
    ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS photo_url TEXT;
    ALTER TABLE public.reviews ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();
    
    -- Enable RLS
    ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

-- Public read for reviews
DROP POLICY IF EXISTS "reviews_public_read" ON public.reviews;
DROP POLICY IF EXISTS "reviews_select_all" ON public.reviews;
CREATE POLICY "reviews_public_read" ON public.reviews
  FOR SELECT
  USING (TRUE);

-- Authenticated insert for reviews
DROP POLICY IF EXISTS "reviews_insert_own" ON public.reviews;
DROP POLICY IF EXISTS "reviews_auth_insert" ON public.reviews;
CREATE POLICY "reviews_auth_insert" ON public.reviews
  FOR INSERT
  TO authenticated
  WITH CHECK (customer_id = auth.uid() OR auth.uid() IS NOT NULL);

-- ── 2. Trigger to automatically recalculate provider rating ─────────────────
CREATE OR REPLACE FUNCTION public.sync_provider_rating_stats()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  target_provider_id UUID;
  new_avg NUMERIC(3,2);
  new_count INT;
BEGIN
  IF (TG_OP = 'DELETE') THEN
    target_provider_id := OLD.provider_id;
  ELSE
    target_provider_id := NEW.provider_id;
  END IF;

  IF target_provider_id IS NOT NULL THEN
    SELECT COALESCE(ROUND(AVG(rating)::numeric, 1), 0.0), COUNT(*)
    INTO new_avg, new_count
    FROM public.reviews
    WHERE provider_id = target_provider_id;

    UPDATE public.service_providers
    SET rating = new_avg,
        review_count = new_count,
        updated_at = NOW()
    WHERE id = target_provider_id;
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_sync_provider_rating ON public.reviews;
CREATE TRIGGER trg_sync_provider_rating
  AFTER INSERT OR UPDATE OR DELETE ON public.reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_provider_rating_stats();

-- ── 3. Subcategories & Categories enhancements ──────────────────────────────
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 99;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS image_url TEXT DEFAULT '';
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.subcategories ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE public.subcategories ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 99;
ALTER TABLE public.subcategories ADD COLUMN IF NOT EXISTS image_url TEXT DEFAULT '';
ALTER TABLE public.subcategories ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';
ALTER TABLE public.subcategories ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- ── 4. Service Providers Location columns ───────────────────────────────────
ALTER TABLE public.service_providers ADD COLUMN IF NOT EXISTS business_latitude DOUBLE PRECISION;
ALTER TABLE public.service_providers ADD COLUMN IF NOT EXISTS business_longitude DOUBLE PRECISION;
ALTER TABLE public.service_providers ADD COLUMN IF NOT EXISTS business_address TEXT DEFAULT '';
ALTER TABLE public.service_providers ADD COLUMN IF NOT EXISTS village TEXT DEFAULT '';
ALTER TABLE public.service_providers ADD COLUMN IF NOT EXISTS taluka TEXT DEFAULT '';
ALTER TABLE public.service_providers ADD COLUMN IF NOT EXISTS district TEXT DEFAULT '';
ALTER TABLE public.service_providers ADD COLUMN IF NOT EXISTS pincode TEXT DEFAULT '';
ALTER TABLE public.service_providers ADD COLUMN IF NOT EXISTS location_updated_at TIMESTAMPTZ;

-- ── 5. Admin Category & Subcategory RPC Functions (Security Definer) ────────
CREATE OR REPLACE FUNCTION public.admin_upsert_category(
  p_id TEXT,
  p_name TEXT,
  p_name_marathi TEXT DEFAULT '',
  p_is_active BOOLEAN DEFAULT TRUE,
  p_description TEXT DEFAULT '',
  p_image_url TEXT DEFAULT '',
  p_sort_order INT DEFAULT 99
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.categories (id, name, name_marathi, is_active, description, image_url, sort_order, updated_at)
  VALUES (p_id, p_name, p_name_marathi, p_is_active, p_description, p_image_url, p_sort_order, NOW())
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    name_marathi = EXCLUDED.name_marathi,
    is_active = EXCLUDED.is_active,
    description = EXCLUDED.description,
    image_url = EXCLUDED.image_url,
    sort_order = EXCLUDED.sort_order,
    updated_at = NOW();

  RETURN jsonb_build_object('success', true, 'id', p_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_toggle_category(
  p_id TEXT,
  p_is_active BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.categories
  SET is_active = p_is_active,
      updated_at = NOW()
  WHERE id = p_id;

  RETURN jsonb_build_object('success', true, 'id', p_id, 'is_active', p_is_active);
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_delete_category(p_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.subcategories WHERE category_id = p_id;
  DELETE FROM public.categories WHERE id = p_id;
  RETURN jsonb_build_object('success', true, 'id', p_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_upsert_subcategory(
  p_id TEXT,
  p_category_id TEXT,
  p_name TEXT,
  p_name_marathi TEXT DEFAULT '',
  p_is_active BOOLEAN DEFAULT TRUE,
  p_description TEXT DEFAULT '',
  p_image_url TEXT DEFAULT '',
  p_sort_order INT DEFAULT 99
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.subcategories (id, category_id, name, name_marathi, is_active, description, image_url, sort_order, updated_at)
  VALUES (p_id, p_category_id, p_name, p_name_marathi, p_is_active, p_description, p_image_url, p_sort_order, NOW())
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    name_marathi = EXCLUDED.name_marathi,
    is_active = EXCLUDED.is_active,
    description = EXCLUDED.description,
    image_url = EXCLUDED.image_url,
    sort_order = EXCLUDED.sort_order,
    updated_at = NOW();

  RETURN jsonb_build_object('success', true, 'id', p_id);
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_toggle_subcategory(
  p_id TEXT,
  p_is_active BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.subcategories
  SET is_active = p_is_active,
      updated_at = NOW()
  WHERE id = p_id;

  RETURN jsonb_build_object('success', true, 'id', p_id, 'is_active', p_is_active);
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_delete_subcategory(p_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  DELETE FROM public.subcategories WHERE id = p_id;
  RETURN jsonb_build_object('success', true, 'id', p_id);
END;
$$;
