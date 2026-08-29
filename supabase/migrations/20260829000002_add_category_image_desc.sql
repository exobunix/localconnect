-- Migration: 20260829000002_add_category_image_desc.sql
-- Description: Adds image_url and description columns to categories and subcategories tables, and grants SELECT privileges on user_profiles to fix permission errors on admin actions.

-- Add image_url and description to categories
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS image_url TEXT DEFAULT '';

-- Add image_url and description to subcategories
ALTER TABLE public.subcategories ADD COLUMN IF NOT EXISTS image_url TEXT DEFAULT '';
ALTER TABLE public.subcategories ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';

-- Grant SELECT privilege on user_profiles to anon and authenticated roles to prevent RLS-related Postgres privilege failures
GRANT SELECT ON public.user_profiles TO anon, authenticated;
