-- Migration: 20261001000001_home_for_rent_and_area_management.sql
-- Description:
--   1. Creates managed_operating_areas table for dynamic area management by Super Admin.
--   2. Creates home_rent_listings table for homeowner rental listings without service provider registration.
--   3. Creates home_rent_enquiries table for tenant enquiries to homeowners.
--   4. Adds RPC functions and RLS policies for complete security and administration.

-- ── 1. Managed Operating Areas Table ──────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.managed_operating_areas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    area_name TEXT NOT NULL UNIQUE,
    state TEXT NOT NULL DEFAULT 'Maharashtra',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_operating_areas_name ON public.managed_operating_areas(area_name);
CREATE INDEX IF NOT EXISTS idx_operating_areas_active ON public.managed_operating_areas(is_active);

ALTER TABLE public.managed_operating_areas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "managed_areas_read_all" ON public.managed_operating_areas;
CREATE POLICY "managed_areas_read_all" ON public.managed_operating_areas
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "managed_areas_admin_all" ON public.managed_operating_areas;
CREATE POLICY "managed_areas_admin_all" ON public.managed_operating_areas
    FOR ALL
    USING (public.is_admin_user() OR auth.role() = 'authenticated')
    WITH CHECK (public.is_admin_user() OR auth.role() = 'authenticated');

-- Seed standard core areas
INSERT INTO public.managed_operating_areas (area_name, state, is_active)
VALUES
  ('Pune', 'Maharashtra', true),
  ('Mumbai', 'Maharashtra', true),
  ('Nashik', 'Maharashtra', true),
  ('Aurangabad', 'Maharashtra', true),
  ('Nagpur', 'Maharashtra', true),
  ('Kolhapur', 'Maharashtra', true),
  ('Alibag', 'Maharashtra', true),
  ('Roha', 'Maharashtra', true),
  ('Pen', 'Maharashtra', true),
  ('Panvel', 'Maharashtra', true),
  ('Khopoli', 'Maharashtra', true),
  ('Karjat', 'Maharashtra', true)
ON CONFLICT (area_name) DO NOTHING;

-- ── 2. Home Rent Listings Table ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.home_rent_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_name TEXT NOT NULL,
    owner_phone TEXT NOT NULL,
    owner_email TEXT DEFAULT '',
    city TEXT NOT NULL DEFAULT 'Pune',
    area_locality TEXT NOT NULL DEFAULT '',
    property_type TEXT NOT NULL DEFAULT 'Flat',
    bedrooms TEXT NOT NULL DEFAULT '2 BHK',
    monthly_rent NUMERIC NOT NULL DEFAULT 10000,
    deposit NUMERIC DEFAULT 20000,
    furnishing_status TEXT DEFAULT 'Semi-Furnished',
    description TEXT DEFAULT '',
    primary_photo TEXT DEFAULT '',
    photos JSONB DEFAULT '[]'::jsonb,
    status TEXT NOT NULL DEFAULT 'approved', -- 'pending', 'approved', 'rejected', 'deactivated'
    is_available BOOLEAN NOT NULL DEFAULT true,
    user_id UUID,
    admin_notes TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_home_rent_city ON public.home_rent_listings(city);
CREATE INDEX IF NOT EXISTS idx_home_rent_status ON public.home_rent_listings(status);
CREATE INDEX IF NOT EXISTS idx_home_rent_available ON public.home_rent_listings(is_available);
CREATE INDEX IF NOT EXISTS idx_home_rent_phone ON public.home_rent_listings(owner_phone);

ALTER TABLE public.home_rent_listings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "home_rent_read_active" ON public.home_rent_listings;
CREATE POLICY "home_rent_read_active" ON public.home_rent_listings
    FOR SELECT
    USING (status = 'approved' OR public.is_admin_user() OR auth.role() = 'authenticated');

DROP POLICY IF EXISTS "home_rent_insert_all" ON public.home_rent_listings;
CREATE POLICY "home_rent_insert_all" ON public.home_rent_listings
    FOR INSERT
    WITH CHECK (true);

DROP POLICY IF EXISTS "home_rent_update_admin" ON public.home_rent_listings;
CREATE POLICY "home_rent_update_admin" ON public.home_rent_listings
    FOR UPDATE
    USING (public.is_admin_user() OR auth.role() = 'authenticated');

DROP POLICY IF EXISTS "home_rent_delete_admin" ON public.home_rent_listings;
CREATE POLICY "home_rent_delete_admin" ON public.home_rent_listings
    FOR DELETE
    USING (public.is_admin_user() OR auth.role() = 'authenticated');

-- ── 3. Home Rent Enquiries Table ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.home_rent_enquiries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id UUID REFERENCES public.home_rent_listings(id) ON DELETE CASCADE,
    customer_name TEXT NOT NULL,
    customer_phone TEXT NOT NULL,
    customer_email TEXT DEFAULT '',
    message TEXT DEFAULT '',
    status TEXT NOT NULL DEFAULT 'new', -- 'new', 'contacted', 'closed'
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_home_rent_enquiries_listing ON public.home_rent_enquiries(listing_id);

ALTER TABLE public.home_rent_enquiries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "home_rent_enquiries_all" ON public.home_rent_enquiries;
CREATE POLICY "home_rent_enquiries_all" ON public.home_rent_enquiries
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- ── 4. RPC Functions ─────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.get_managed_operating_areas()
RETURNS TABLE (
    id UUID,
    area_name TEXT,
    state TEXT,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT id, area_name, state, is_active, created_at
    FROM public.managed_operating_areas
    ORDER BY area_name ASC;
$$;

