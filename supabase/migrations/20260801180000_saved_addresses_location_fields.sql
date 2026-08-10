-- Enhance saved_addresses with full location fields for multi-address support
-- Timestamp: 20260801180000

-- Add location fields to saved_addresses
ALTER TABLE public.saved_addresses
  ADD COLUMN IF NOT EXISTS village TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS taluka TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS district TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS full_address TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS location_method TEXT DEFAULT 'manual';

-- Add address_icon column for quick visual identification
ALTER TABLE public.saved_addresses
  ADD COLUMN IF NOT EXISTS address_icon TEXT DEFAULT 'location';
