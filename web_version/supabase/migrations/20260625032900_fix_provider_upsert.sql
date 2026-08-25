-- Fix: Add UNIQUE constraint on service_providers.user_id
-- This is required for the upsert onConflict: 'user_id' to work correctly.

-- Add unique constraint on user_id (idempotent via index)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'service_providers_user_id_key'
      AND conrelid = 'public.service_providers'::regclass
  ) THEN
    ALTER TABLE public.service_providers
    ADD CONSTRAINT service_providers_user_id_key UNIQUE (user_id);
  END IF;
END $$;
