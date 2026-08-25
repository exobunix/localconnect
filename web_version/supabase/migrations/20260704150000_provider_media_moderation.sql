-- Provider Media Moderation Migration
-- Adds media_moderation_status column to provider_portfolio and gallery_photos
-- Creates provider_media_items table for granular per-item moderation

-- ─── Media Moderation Status on provider_portfolio ───────────────────────────
ALTER TABLE public.provider_portfolio
  ADD COLUMN IF NOT EXISTS moderation_status TEXT DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS moderation_note TEXT,
  ADD COLUMN IF NOT EXISTS moderated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS moderated_at TIMESTAMPTZ;

-- ─── Per-item Media Table ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.provider_media_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  media_type TEXT NOT NULL DEFAULT 'photo',
  media_url TEXT NOT NULL,
  thumbnail_url TEXT,
  caption TEXT,
  category TEXT DEFAULT 'gallery',
  moderation_status TEXT NOT NULL DEFAULT 'pending',
  moderation_note TEXT,
  moderated_by UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  moderated_at TIMESTAMPTZ,
  uploaded_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_provider_media_items_provider_id
  ON public.provider_media_items(provider_id);

CREATE INDEX IF NOT EXISTS idx_provider_media_items_status
  ON public.provider_media_items(moderation_status);

CREATE INDEX IF NOT EXISTS idx_provider_media_items_type
  ON public.provider_media_items(media_type);

-- ─── RLS ─────────────────────────────────────────────────────────────────────
ALTER TABLE public.provider_media_items ENABLE ROW LEVEL SECURITY;

-- Admin full access function (safe - queries auth.users not user_profiles)
CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
  SELECT 1 FROM auth.users au
  WHERE au.id = auth.uid()
    AND (au.raw_user_meta_data->>'role' = 'admin'
      OR au.raw_app_meta_data->>'role' = 'admin')
)
$$;

DROP POLICY IF EXISTS "admin_full_access_media_items" ON public.provider_media_items;
CREATE POLICY "admin_full_access_media_items"
  ON public.provider_media_items
  FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

DROP POLICY IF EXISTS "providers_manage_own_media" ON public.provider_media_items;
CREATE POLICY "providers_manage_own_media"
  ON public.provider_media_items
  FOR ALL
  TO authenticated
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

DROP POLICY IF EXISTS "customers_view_approved_media" ON public.provider_media_items;
CREATE POLICY "customers_view_approved_media"
  ON public.provider_media_items
  FOR SELECT
  TO authenticated
  USING (moderation_status = 'approved');

-- ─── Seed sample pending media for demo ──────────────────────────────────────
DO $$
DECLARE
  sp_id UUID;
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'service_providers'
  ) THEN
    SELECT id INTO sp_id FROM public.service_providers LIMIT 1;
    IF sp_id IS NOT NULL THEN
      INSERT INTO public.provider_media_items
        (provider_id, media_type, media_url, thumbnail_url, caption, category, moderation_status)
      VALUES
        (sp_id, 'photo', 'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg', 'https://images.pexels.com/photos/1571460/pexels-photo-1571460.jpeg?w=400', 'Living room renovation', 'gallery', 'pending'),
        (sp_id, 'photo', 'https://images.pexels.com/photos/276724/pexels-photo-276724.jpeg', 'https://images.pexels.com/photos/276724/pexels-photo-276724.jpeg?w=400', 'Kitchen installation', 'gallery', 'pending'),
        (sp_id, 'photo', 'https://images.pexels.com/photos/1080721/pexels-photo-1080721.jpeg', 'https://images.pexels.com/photos/1080721/pexels-photo-1080721.jpeg?w=400', 'Bathroom plumbing work', 'portfolio', 'approved'),
        (sp_id, 'photo', 'https://images.pexels.com/photos/3184418/pexels-photo-3184418.jpeg', 'https://images.pexels.com/photos/3184418/pexels-photo-3184418.jpeg?w=400', 'Event decoration setup', 'portfolio', 'pending'),
        (sp_id, 'video', 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', null, 'Wedding ceremony highlights', 'portfolio', 'pending'),
        (sp_id, 'photo', 'https://images.pixabay.com/photo/2016/11/29/03/53/house-1867187_1280.jpg', 'https://images.pixabay.com/photo/2016/11/29/03/53/house-1867187_640.jpg', 'Exterior painting job', 'gallery', 'rejected')
      ON CONFLICT (id) DO NOTHING;
    END IF;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Seed media items failed: %', SQLERRM;
END $$;
