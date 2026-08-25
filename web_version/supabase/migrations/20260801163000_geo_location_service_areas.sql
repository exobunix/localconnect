-- ============================================================
-- Smart Geo-Location & Service Area Management
-- ============================================================

-- Enable PostGIS extension for geospatial queries
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ─── Customer Location ────────────────────────────────────────────────────────

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS latitude         DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude        DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS full_address     TEXT,
  ADD COLUMN IF NOT EXISTS village          TEXT,
  ADD COLUMN IF NOT EXISTS taluka           TEXT,
  ADD COLUMN IF NOT EXISTS district         TEXT,
  ADD COLUMN IF NOT EXISTS state            TEXT DEFAULT 'Maharashtra',
  ADD COLUMN IF NOT EXISTS pincode          TEXT,
  ADD COLUMN IF NOT EXISTS location_method  TEXT DEFAULT 'manual',
  ADD COLUMN IF NOT EXISTS location_updated_at TIMESTAMPTZ;

-- ─── Provider Location & Service Areas ───────────────────────────────────────

ALTER TABLE service_providers
  ADD COLUMN IF NOT EXISTS business_latitude   DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS business_longitude  DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS business_address    TEXT,
  ADD COLUMN IF NOT EXISTS village             TEXT,
  ADD COLUMN IF NOT EXISTS taluka              TEXT,
  ADD COLUMN IF NOT EXISTS district            TEXT,
  ADD COLUMN IF NOT EXISTS state               TEXT DEFAULT 'Maharashtra',
  ADD COLUMN IF NOT EXISTS pincode             TEXT,
  ADD COLUMN IF NOT EXISTS service_radius_km   DOUBLE PRECISION DEFAULT 10,
  ADD COLUMN IF NOT EXISTS service_mode        TEXT DEFAULT 'radius',
  ADD COLUMN IF NOT EXISTS service_villages    TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS service_talukas     TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS service_districts   TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS location_updated_at TIMESTAMPTZ;

-- ─── Geospatial Indexes ───────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_user_profiles_location
  ON user_profiles (latitude, longitude)
  WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_service_providers_location
  ON service_providers (business_latitude, business_longitude)
  WHERE business_latitude IS NOT NULL AND business_longitude IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_service_providers_district
  ON service_providers USING gin(service_districts);

CREATE INDEX IF NOT EXISTS idx_service_providers_taluka
  ON service_providers USING gin(service_talukas);

CREATE INDEX IF NOT EXISTS idx_service_providers_villages
  ON service_providers USING gin(service_villages);

-- ─── Nearby Providers Function ────────────────────────────────────────────────
-- Returns providers within radius OR matching admin areas

CREATE OR REPLACE FUNCTION get_nearby_providers(
  p_lat         DOUBLE PRECISION,
  p_lng         DOUBLE PRECISION,
  p_radius_km   DOUBLE PRECISION DEFAULT 50,
  p_village     TEXT DEFAULT NULL,
  p_taluka      TEXT DEFAULT NULL,
  p_district    TEXT DEFAULT NULL,
  p_category    TEXT DEFAULT NULL,
  p_limit       INT  DEFAULT 50,
  p_offset      INT  DEFAULT 0
)
RETURNS TABLE (
  id                  UUID,
  business_name       TEXT,
  owner_name          TEXT,
  category            TEXT,
  subcategory         TEXT,
  business_latitude   DOUBLE PRECISION,
  business_longitude  DOUBLE PRECISION,
  business_address    TEXT,
  village             TEXT,
  taluka              TEXT,
  district            TEXT,
  state               TEXT,
  pincode             TEXT,
  service_radius_km   DOUBLE PRECISION,
  service_mode        TEXT,
  service_villages    TEXT[],
  service_talukas     TEXT[],
  service_districts   TEXT[],
  rating              DOUBLE PRECISION,
  review_count        INT,
  is_verified         BOOLEAN,
  is_open             BOOLEAN,
  image_url           TEXT,
  distance_km         DOUBLE PRECISION,
  match_type          TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT
    pr.id,
    pr.business_name::TEXT,
    pr.owner_name::TEXT,
    pr.category::TEXT,
    pr.subcategory::TEXT,
    pr.business_latitude,
    pr.business_longitude,
    pr.business_address::TEXT,
    pr.village::TEXT,
    pr.taluka::TEXT,
    pr.district::TEXT,
    pr.state::TEXT,
    pr.pincode::TEXT,
    pr.service_radius_km,
    pr.service_mode::TEXT,
    pr.service_villages,
    pr.service_talukas,
    pr.service_districts,
    COALESCE(pr.rating, 0.0)::DOUBLE PRECISION,
    COALESCE(pr.review_count, 0)::INT,
    COALESCE(pr.is_verified, false)::BOOLEAN,
    COALESCE(pr.is_open, true)::BOOLEAN,
    pr.image_url::TEXT,
    -- Haversine distance in km
    CASE
      WHEN pr.business_latitude IS NOT NULL AND pr.business_longitude IS NOT NULL
      THEN (
        6371 * acos(
          LEAST(1.0, cos(radians(p_lat)) * cos(radians(pr.business_latitude))
          * cos(radians(pr.business_longitude) - radians(p_lng))
          + sin(radians(p_lat)) * sin(radians(pr.business_latitude)))
        )
      )
      ELSE 9999.0
    END::DOUBLE PRECISION AS distance_km,
    -- Match type: radius or area
    CASE
      WHEN pr.business_latitude IS NOT NULL AND pr.business_longitude IS NOT NULL
        AND (
          6371 * acos(
            LEAST(1.0, cos(radians(p_lat)) * cos(radians(pr.business_latitude))
            * cos(radians(pr.business_longitude) - radians(p_lng))
            + sin(radians(p_lat)) * sin(radians(pr.business_latitude)))
          )
        ) <= COALESCE(pr.service_radius_km, 10)
      THEN 'radius'
      ELSE 'area'
    END::TEXT AS match_type
  FROM service_providers pr
  WHERE
    pr.is_active = true
    AND (p_category IS NULL OR pr.category = p_category)
    AND (
      -- GPS radius match
      (
        pr.business_latitude IS NOT NULL
        AND pr.business_longitude IS NOT NULL
        AND (
          6371 * acos(
            LEAST(1.0, cos(radians(p_lat)) * cos(radians(pr.business_latitude))
            * cos(radians(pr.business_longitude) - radians(p_lng))
            + sin(radians(p_lat)) * sin(radians(pr.business_latitude)))
          )
        ) <= COALESCE(pr.service_radius_km, 10)
      )
      OR
      -- Administrative area match
      (
        (p_village IS NOT NULL AND pr.service_villages @> ARRAY[p_village])
        OR (p_taluka IS NOT NULL AND pr.service_talukas @> ARRAY[p_taluka])
        OR (p_district IS NOT NULL AND pr.service_districts @> ARRAY[p_district])
      )
    )
  ORDER BY
    distance_km ASC,
    COALESCE(pr.rating, 0) DESC,
    COALESCE(pr.is_verified, false) DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$;

-- ─── Booking Service Area Validation Function ─────────────────────────────────

CREATE OR REPLACE FUNCTION validate_provider_service_area(
  p_provider_id UUID,
  p_customer_lat DOUBLE PRECISION,
  p_customer_lng DOUBLE PRECISION,
  p_customer_village TEXT DEFAULT NULL,
  p_customer_taluka  TEXT DEFAULT NULL,
  p_customer_district TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_provider service_providers%ROWTYPE;
  v_distance DOUBLE PRECISION;
  v_in_radius BOOLEAN := false;
  v_in_area   BOOLEAN := false;
BEGIN
  SELECT * INTO v_provider FROM service_providers WHERE id = p_provider_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('eligible', false, 'reason', 'Provider not found');
  END IF;

  -- Calculate distance
  IF v_provider.business_latitude IS NOT NULL AND v_provider.business_longitude IS NOT NULL THEN
    v_distance := 6371 * acos(
      LEAST(1.0, cos(radians(p_customer_lat)) * cos(radians(v_provider.business_latitude))
      * cos(radians(v_provider.business_longitude) - radians(p_customer_lng))
      + sin(radians(p_customer_lat)) * sin(radians(v_provider.business_latitude)))
    );
    v_in_radius := v_distance <= COALESCE(v_provider.service_radius_km, 10);
  END IF;

  -- Check admin areas
  IF (p_customer_village IS NOT NULL AND v_provider.service_villages @> ARRAY[p_customer_village])
     OR (p_customer_taluka IS NOT NULL AND v_provider.service_talukas @> ARRAY[p_customer_taluka])
     OR (p_customer_district IS NOT NULL AND v_provider.service_districts @> ARRAY[p_customer_district])
  THEN
    v_in_area := true;
  END IF;

  IF v_in_radius OR v_in_area THEN
    RETURN jsonb_build_object(
      'eligible', true,
      'distance_km', COALESCE(v_distance, -1),
      'match_type', CASE WHEN v_in_radius THEN 'radius' ELSE 'area' END
    );
  ELSE
    RETURN jsonb_build_object(
      'eligible', false,
      'reason', 'This provider does not currently serve your location.',
      'distance_km', COALESCE(v_distance, -1)
    );
  END IF;
END;
$$;

-- ─── RLS Policies ─────────────────────────────────────────────────────────────

-- user_profiles: users can update their own location
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'user_profiles' AND policyname = 'users_update_own_location'
  ) THEN
    CREATE POLICY users_update_own_location ON user_profiles
      FOR UPDATE USING (auth.uid() = id)
      WITH CHECK (auth.uid() = id);
  END IF;
END $$;

-- service_providers: providers can update their own location/service areas
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'service_providers' AND policyname = 'providers_update_own_location'
  ) THEN
    CREATE POLICY providers_update_own_location ON service_providers
      FOR UPDATE USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- Grant execute on functions
GRANT EXECUTE ON FUNCTION get_nearby_providers TO authenticated, anon;
GRANT EXECUTE ON FUNCTION validate_provider_service_area TO authenticated, anon;
