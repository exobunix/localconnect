-- Provider Photos: storage bucket + provider_photos table
-- Migration: 20260624200000_provider_photos

-- ─── STORAGE BUCKET ──────────────────────────────────────────────────────────

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'provider-photos',
    'provider-photos',
    true,
    10485760,
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: public can view, authenticated providers can manage their own
DROP POLICY IF EXISTS "provider_photos_public_read" ON storage.objects;
CREATE POLICY "provider_photos_public_read"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'provider-photos');

DROP POLICY IF EXISTS "provider_photos_authenticated_upload" ON storage.objects;
CREATE POLICY "provider_photos_authenticated_upload"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'provider-photos' AND owner = auth.uid());

DROP POLICY IF EXISTS "provider_photos_owner_update" ON storage.objects;
CREATE POLICY "provider_photos_owner_update"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'provider-photos' AND owner = auth.uid());

DROP POLICY IF EXISTS "provider_photos_owner_delete" ON storage.objects;
CREATE POLICY "provider_photos_owner_delete"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'provider-photos' AND owner = auth.uid());

-- ─── PROVIDER PHOTOS TABLE ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.provider_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL DEFAULT '',
    storage_path TEXT NOT NULL DEFAULT '',
    caption TEXT DEFAULT '',
    sort_order INTEGER DEFAULT 0,
    is_cover BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_provider_photos_provider_id ON public.provider_photos(provider_id);
CREATE INDEX IF NOT EXISTS idx_provider_photos_user_id ON public.provider_photos(user_id);

ALTER TABLE public.provider_photos ENABLE ROW LEVEL SECURITY;

-- Public can view all provider photos
DROP POLICY IF EXISTS "provider_photos_public_select" ON public.provider_photos;
CREATE POLICY "provider_photos_public_select"
ON public.provider_photos FOR SELECT TO public
USING (true);

-- Providers can insert their own photos
DROP POLICY IF EXISTS "provider_photos_owner_insert" ON public.provider_photos;
CREATE POLICY "provider_photos_owner_insert"
ON public.provider_photos FOR INSERT TO authenticated
WITH CHECK (user_id = auth.uid());

-- Providers can update their own photos
DROP POLICY IF EXISTS "provider_photos_owner_update_row" ON public.provider_photos;
CREATE POLICY "provider_photos_owner_update_row"
ON public.provider_photos FOR UPDATE TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Providers can delete their own photos
DROP POLICY IF EXISTS "provider_photos_owner_delete_row" ON public.provider_photos;
CREATE POLICY "provider_photos_owner_delete_row"
ON public.provider_photos FOR DELETE TO authenticated
USING (user_id = auth.uid());
