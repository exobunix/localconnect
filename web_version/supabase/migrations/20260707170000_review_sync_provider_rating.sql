-- Migration: Sync reviews to provider profile (rating + review_count)
-- Timestamp: 20260707170000

-- 1. Allow all authenticated users to read reviews (needed for provider profile)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'reviews' AND policyname = 'public_read_reviews'
  ) THEN
    CREATE POLICY public_read_reviews ON public.reviews
      FOR SELECT TO authenticated
      USING (true);
  END IF;
END $$;

-- 2. Function: recalculate and update provider rating + review_count after review insert
CREATE OR REPLACE FUNCTION public.sync_provider_rating_on_review()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  avg_rating NUMERIC;
  total_count INTEGER;
BEGIN
  -- Calculate new average rating and count for this provider
  SELECT
    ROUND(AVG(rating)::NUMERIC, 1),
    COUNT(*)
  INTO avg_rating, total_count
  FROM public.reviews
  WHERE provider_id = NEW.provider_id;

  -- Update service_providers table
  UPDATE public.service_providers
  SET
    rating = COALESCE(avg_rating, 0),
    review_count = COALESCE(total_count, 0)
  WHERE id = NEW.provider_id;

  RETURN NEW;
END;
$$;

-- 3. Trigger: fire after review insert
DROP TRIGGER IF EXISTS on_review_sync_provider ON public.reviews;
CREATE TRIGGER on_review_sync_provider
  AFTER INSERT ON public.reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_provider_rating_on_review();

-- 4. Add reviewed column to orders table if not already present (idempotent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'orders' AND column_name = 'reviewed'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN reviewed BOOLEAN DEFAULT FALSE;
  END IF;
END $$;

-- 5. Backfill existing provider ratings from existing reviews
UPDATE public.service_providers sp
SET
  rating = sub.avg_rating,
  review_count = sub.cnt
FROM (
  SELECT
    provider_id,
    ROUND(AVG(rating)::NUMERIC, 1) AS avg_rating,
    COUNT(*) AS cnt
  FROM public.reviews
  GROUP BY provider_id
) sub
WHERE sp.id = sub.provider_id;
