-- ============================================================
-- Admin Location Search Settings
-- Configurable search radius rules without code changes
-- ============================================================

-- ─── Admin Location Settings Table ───────────────────────────────────────────

CREATE TABLE IF NOT EXISTS admin_location_settings (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  setting_key             TEXT UNIQUE NOT NULL,
  setting_value           TEXT NOT NULL,
  description             TEXT,
  updated_at              TIMESTAMPTZ DEFAULT now(),
  updated_by              UUID REFERENCES auth.users(id)
);

-- ─── Default Settings ─────────────────────────────────────────────────────────

INSERT INTO admin_location_settings (setting_key, setting_value, description) VALUES
  ('default_search_radius_km',  '10',   'Default search radius in km when customer opens discovery'),
  ('max_search_radius_km',      '100',  'Maximum allowed search radius in km'),
  ('smart_expand_step1_km',     '5',    'First smart expansion radius in km'),
  ('smart_expand_step2_km',     '10',   'Second smart expansion radius in km'),
  ('smart_expand_step3_km',     '20',   'Third smart expansion radius in km'),
  ('smart_expand_step4_km',     '50',   'Fourth smart expansion radius in km (final fallback)'),
  ('min_providers_threshold',   '3',    'Minimum providers before expanding radius'),
  ('category_radius_shop',      '5',    'Default service radius for Shop category in km'),
  ('category_radius_transport', '50',   'Default service radius for Transport category in km'),
  ('category_radius_home_maintenance', '15', 'Default service radius for Home Maintenance in km'),
  ('category_radius_delivery',  '20',   'Default service radius for Delivery category in km'),
  ('category_radius_events',    '30',   'Default service radius for Events category in km'),
  ('category_radius_rent',      '10',   'Default service radius for Rent category in km'),
  ('category_radius_beauty',    '10',   'Default service radius for Beauty category in km'),
  ('category_radius_doctor',    '15',   'Default service radius for Doctor category in km'),
  ('category_radius_food',      '8',    'Default service radius for Food category in km')
ON CONFLICT (setting_key) DO NOTHING;

-- ─── RLS Policies ─────────────────────────────────────────────────────────────

ALTER TABLE admin_location_settings ENABLE ROW LEVEL SECURITY;

-- Anyone can read settings (needed for customer search)
CREATE POLICY "Anyone can read location settings"
  ON admin_location_settings FOR SELECT
  USING (true);

-- Only admins can modify settings
CREATE POLICY "Admins can update location settings"
  ON admin_location_settings FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ─── Helper Function: Get Setting Value ───────────────────────────────────────

CREATE OR REPLACE FUNCTION get_location_setting(p_key TEXT, p_default TEXT DEFAULT '10')
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_value TEXT;
BEGIN
  SELECT setting_value INTO v_value
  FROM admin_location_settings
  WHERE setting_key = p_key;
  RETURN COALESCE(v_value, p_default);
END;
$$;

-- ─── Enhanced Nearby Providers Function with Smart Expansion ─────────────────

CREATE OR REPLACE FUNCTION get_nearby_providers_smart(
  p_lat         DOUBLE PRECISION,
  p_lng         DOUBLE PRECISION,
  p_radius_km   DOUBLE PRECISION DEFAULT NULL,
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
  match_type          TEXT,
  effective_radius_km DOUBLE PRECISION
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_search_radius DOUBLE PRECISION;
  v_default_radius DOUBLE PRECISION;
  v_cat_key TEXT;
BEGIN
  -- Determine search radius
  IF p_radius_km IS NOT NULL THEN
    v_search_radius := p_radius_km;
  ELSE
    -- Get category-specific default or global default
    IF p_category IS NOT NULL THEN
      v_cat_key := 'category_radius_' || p_category;
      v_default_radius := get_location_setting(v_cat_key, '10')::DOUBLE PRECISION;
    ELSE
      v_default_radius := get_location_setting('default_search_radius_km', '10')::DOUBLE PRECISION;
    END IF;
    v_search_radius := v_default_radius;
  END IF;

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
    END::TEXT AS match_type,
    v_search_radius AS effective_radius_km
  FROM service_providers pr
  WHERE
    pr.is_active = true
    AND (p_category IS NULL OR pr.category = p_category)
    AND (
      -- Provider is within customer's search radius AND customer is within provider's service radius
      (
        pr.business_latitude IS NOT NULL
        AND pr.business_longitude IS NOT NULL
        AND (
          6371 * acos(
            LEAST(1.0, cos(radians(p_lat)) * cos(radians(pr.business_latitude))
            * cos(radians(pr.business_longitude) - radians(p_lng))
            + sin(radians(p_lat)) * sin(radians(pr.business_latitude)))
          )
        ) <= v_search_radius
        AND (
          6371 * acos(
            LEAST(1.0, cos(radians(p_lat)) * cos(radians(pr.business_latitude))
            * cos(radians(pr.business_longitude) - radians(p_lng))
            + sin(radians(p_lat)) * sin(radians(pr.business_latitude)))
          )
        ) <= COALESCE(pr.service_radius_km, 10)
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

-- ─── Grant execute permissions ─────────────────────────────────────────────────

GRANT EXECUTE ON FUNCTION get_location_setting(TEXT, TEXT) TO authenticated, anon;
GRANT EXECUTE ON FUNCTION get_nearby_providers_smart(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, TEXT, INT, INT) TO authenticated, anon;
