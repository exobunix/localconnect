-- ============================================================================
-- Migration: 20260826000000_fix_service_providers_anon_rls.sql
-- Description: Allow public (anon and authenticated) read access to active
--              and approved service providers for homepage and guest discovery.
-- ============================================================================

ALTER TABLE public.service_providers ENABLE ROW LEVEL SECURITY;

-- Drop previous restrictive policy
DROP POLICY IF EXISTS "public_read_active_providers" ON public.service_providers;
DROP POLICY IF EXISTS "public_read_service_providers" ON public.service_providers;

-- Allow public (anon + authenticated) to view active or approved providers
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

-- Ensure table permissions for both anon and authenticated roles
GRANT SELECT ON public.service_providers TO anon, authenticated;
