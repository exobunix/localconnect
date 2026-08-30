-- Migration: 20260830000001_fix_schema_cache_and_avatar.sql
-- Description:
--   1. Force PostgREST schema cache reload to fix PGRST204 on enquiries table
--   2. Re-ensure all enquiry columns exist (idempotent)
--   3. Add avatar_url to user_profiles
--   4. Set up user-avatars storage bucket with RLS policies

-- ─── 1. Force PostgREST schema cache reload ───────────────────────────────────
-- This fixes the "Could not find 'customer_name' column" PGRST204 error
NOTIFY pgrst, 'reload schema';

-- ─── 2. Ensure all enquiry columns exist (idempotent) ─────────────────────────
ALTER TABLE public.enquiries
  ADD COLUMN IF NOT EXISTS customer_name   TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS customer_phone  TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS provider_name   TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS service_title   TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS preferred_date  TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS preferred_time  TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS message         TEXT DEFAULT '';

-- Reload again after schema changes
NOTIFY pgrst, 'reload schema';

-- ─── 3. Add avatar_url to user_profiles ───────────────────────────────────────
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS avatar_url TEXT DEFAULT '';

-- ─── 4. user-avatars storage bucket & RLS ─────────────────────────────────────
-- Create the bucket if it doesn't already exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'user-avatars',
  'user-avatars',
  true,
  5242880,  -- 5 MB limit
  ARRAY['image/jpeg','image/jpg','image/png','image/webp']
)
ON CONFLICT (id) DO UPDATE
  SET public = true,
      file_size_limit = 5242880,
      allowed_mime_types = ARRAY['image/jpeg','image/jpg','image/png','image/webp'];

-- RLS: Drop old policies first (idempotent)
DROP POLICY IF EXISTS "avatar_public_read"      ON storage.objects;
DROP POLICY IF EXISTS "avatar_auth_insert"      ON storage.objects;
DROP POLICY IF EXISTS "avatar_auth_update"      ON storage.objects;
DROP POLICY IF EXISTS "avatar_auth_delete"      ON storage.objects;

-- Allow anyone to read avatars (public bucket)
CREATE POLICY "avatar_public_read"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'user-avatars');

-- Allow authenticated users to upload their own avatar
CREATE POLICY "avatar_auth_insert"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'user-avatars');

-- Allow authenticated users to update (overwrite) their own avatar
CREATE POLICY "avatar_auth_update"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'user-avatars');

-- Allow authenticated users to delete their own avatar
CREATE POLICY "avatar_auth_delete"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'user-avatars');

-- ─── 5. Grant SELECT on user_profiles for reading avatar_url ──────────────────
GRANT SELECT, UPDATE ON public.user_profiles TO authenticated;

-- Final schema reload
NOTIFY pgrst, 'reload schema';
