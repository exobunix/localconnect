-- Migration: 20260829000000_fix_category_management_rls.sql
-- Description: Fixes RLS policies on categories and subcategories to avoid querying user_profiles directly.
-- Instead, utilizes the SECURITY DEFINER function public.is_admin_user() which handles privilege elevation cleanly.

-- Drop old categories policies
DROP POLICY IF EXISTS "Admin write categories" ON public.categories;
DROP POLICY IF EXISTS "categories_admin_all" ON public.categories;
DROP POLICY IF EXISTS "Public read categories" ON public.categories;
DROP POLICY IF EXISTS "categories_public_read" ON public.categories;

-- Recreate SELECT policy (public read)
CREATE POLICY "categories_public_read" ON public.categories
  FOR SELECT USING (TRUE);

-- Recreate admin management policy using is_admin_user()
CREATE POLICY "categories_admin_write" ON public.categories
  FOR ALL
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- Drop old subcategories policies
DROP POLICY IF EXISTS "Admin write subcategories" ON public.subcategories;
DROP POLICY IF EXISTS "subcategories_admin_all" ON public.subcategories;
DROP POLICY IF EXISTS "Public read subcategories" ON public.subcategories;
DROP POLICY IF EXISTS "subcategories_public_read" ON public.subcategories;

-- Recreate SELECT policy (public read)
CREATE POLICY "subcategories_public_read" ON public.subcategories
  FOR SELECT USING (TRUE);

-- Recreate admin management policy using is_admin_user()
CREATE POLICY "subcategories_admin_write" ON public.subcategories
  FOR ALL
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());
