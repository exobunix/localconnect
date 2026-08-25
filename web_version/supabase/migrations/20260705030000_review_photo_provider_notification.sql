-- Migration: Add photo_url to reviews + provider notification trigger
-- Timestamp: 20260705030000

-- 1. Add photo_url column to reviews table
ALTER TABLE public.reviews
ADD COLUMN IF NOT EXISTS photo_url TEXT DEFAULT NULL;

-- 2. Function: notify provider when a review is submitted
CREATE OR REPLACE FUNCTION public.notify_provider_on_review()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  provider_user_id UUID;
  customer_name TEXT;
  provider_biz_name TEXT;
BEGIN
  -- Get the provider's user_id from service_providers
  SELECT user_id INTO provider_user_id
  FROM public.service_providers
  WHERE id = NEW.provider_id
  LIMIT 1;

  -- Get customer name
  SELECT full_name INTO customer_name
  FROM public.user_profiles
  WHERE id = NEW.customer_id
  LIMIT 1;

  -- Get provider business name
  SELECT business_name INTO provider_biz_name
  FROM public.service_providers
  WHERE id = NEW.provider_id
  LIMIT 1;

  -- Insert notification for provider if user_id found
  IF provider_user_id IS NOT NULL THEN
    INSERT INTO public.notifications (
      user_id,
      title,
      body,
      type,
      related_id,
      is_read,
      created_at
    ) VALUES (
      provider_user_id,
      'New Review Received',
      COALESCE(customer_name, 'A customer') || ' rated your service ' || NEW.rating || '/5 stars.',
      'review',
      NEW.id,
      false,
      now()
    );
  END IF;

  RETURN NEW;
END;
$$;

-- 3. Trigger: fire after review insert
DROP TRIGGER IF EXISTS on_review_inserted ON public.reviews;
CREATE TRIGGER on_review_inserted
  AFTER INSERT ON public.reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_provider_on_review();

-- 4. Index for photo_url lookups (optional, for filtering reviews with photos)
CREATE INDEX IF NOT EXISTS idx_reviews_photo_url ON public.reviews(photo_url) WHERE photo_url IS NOT NULL;
