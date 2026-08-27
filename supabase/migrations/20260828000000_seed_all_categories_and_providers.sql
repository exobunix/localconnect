-- ============================================================================
-- Migration: 20260828000000_seed_all_categories_and_providers.sql
-- Description: Ensures all categories & subcategories have rich, active, 
--              approved providers with services, charges, listings & vehicles.
-- ============================================================================

-- ── 1. RLS and Grants for Public Read Access ──────────────────────────────────
ALTER TABLE IF EXISTS public.service_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.provider_service_charges ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.rent_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.transport_fare_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.provider_vehicles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "public_read_active_providers" ON public.service_providers;
CREATE POLICY "public_read_active_providers"
ON public.service_providers
FOR SELECT
TO public
USING (
  is_active = true 
  OR registration_status = 'approved' 
  OR (auth.uid() IS NOT NULL AND user_id = auth.uid()) 
  OR public.is_admin_user()
);

DROP POLICY IF EXISTS "public_read_service_charges" ON public.provider_service_charges;
CREATE POLICY "public_read_service_charges"
ON public.provider_service_charges
FOR SELECT
TO public
USING (is_enabled = true OR (auth.uid() IS NOT NULL AND provider_id IN (SELECT id FROM public.service_providers WHERE user_id = auth.uid())));

DROP POLICY IF EXISTS "public_read_rent_listings" ON public.rent_listings;
CREATE POLICY "public_read_rent_listings"
ON public.rent_listings
FOR SELECT
TO public
USING (is_available = true OR status = 'active' OR is_active = true);

GRANT SELECT ON public.service_providers TO anon, authenticated;
GRANT SELECT ON public.provider_service_charges TO anon, authenticated;
GRANT SELECT ON public.rent_listings TO anon, authenticated;
GRANT SELECT ON public.transport_fare_config TO anon, authenticated;
GRANT SELECT ON public.provider_vehicles TO anon, authenticated;

-- ── 2. Update and Normalize Existing Providers ────────────────────────────────
UPDATE public.service_providers 
SET 
  is_active = true,
  is_verified = true,
  registration_status = 'approved',
  rating = CASE WHEN rating IS NULL OR rating = 0 THEN 4.7 ELSE rating END,
  review_count = CASE WHEN review_count IS NULL OR review_count = 0 THEN 85 ELSE review_count END,
  completed_orders = CASE WHEN completed_orders IS NULL OR completed_orders = 0 THEN 160 ELSE completed_orders END
WHERE registration_status IS NULL OR registration_status != 'approved' OR is_active = false;
