-- Add photos column to provider_service_charges for per-service photos
ALTER TABLE public.provider_service_charges
  ADD COLUMN IF NOT EXISTS photos TEXT[] DEFAULT ARRAY[]::TEXT[],
  ADD COLUMN IF NOT EXISTS min_price NUMERIC(10,2) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS max_price NUMERIC(10,2) DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS description TEXT DEFAULT NULL;
