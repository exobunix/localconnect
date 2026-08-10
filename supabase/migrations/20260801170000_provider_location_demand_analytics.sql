-- ─── Provider Location Demand Analytics ──────────────────────────────────────
-- Adds a function that aggregates requests, bookings, and revenue by
-- village/taluka for a given provider, joining orders with customer profiles.
-- ─────────────────────────────────────────────────────────────────────────────

-- Function: get_provider_location_demand
-- Returns aggregated demand stats per village and taluka for a provider.
CREATE OR REPLACE FUNCTION public.get_provider_location_demand(
  p_provider_id UUID
)
RETURNS TABLE(
  area_type        TEXT,
  area_name        TEXT,
  total_requests   BIGINT,
  total_bookings   BIGINT,
  total_revenue    NUMERIC,
  last_request_at  TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Village-level aggregation
  RETURN QUERY
  SELECT
    'village'::TEXT                                          AS area_type,
    COALESCE(up.village, 'Unknown')::TEXT                   AS area_name,
    COUNT(o.id)::BIGINT                                     AS total_requests,
    COUNT(o.id) FILTER (
      WHERE o.status IN ('active','upcoming','completed')
    )::BIGINT                                               AS total_bookings,
    COALESCE(
      SUM(
        CASE WHEN o.status = 'completed'
          THEN CAST(
            REGEXP_REPLACE(COALESCE(o.amount,'0'), '[^0-9.]', '', 'g')
            AS NUMERIC
          )
          ELSE 0
        END
      ), 0
    )                                                       AS total_revenue,
    MAX(o.created_at)                                       AS last_request_at
  FROM public.orders o
  JOIN public.user_profiles up ON up.id = o.customer_id
  WHERE o.provider_id = p_provider_id
    AND COALESCE(up.village, '') <> ''
  GROUP BY up.village

  UNION ALL

  -- Taluka-level aggregation
  SELECT
    'taluka'::TEXT                                          AS area_type,
    COALESCE(up.taluka, 'Unknown')::TEXT                   AS area_name,
    COUNT(o.id)::BIGINT                                     AS total_requests,
    COUNT(o.id) FILTER (
      WHERE o.status IN ('active','upcoming','completed')
    )::BIGINT                                               AS total_bookings,
    COALESCE(
      SUM(
        CASE WHEN o.status = 'completed'
          THEN CAST(
            REGEXP_REPLACE(COALESCE(o.amount,'0'), '[^0-9.]', '', 'g')
            AS NUMERIC
          )
          ELSE 0
        END
      ), 0
    )                                                       AS total_revenue,
    MAX(o.created_at)                                       AS last_request_at
  FROM public.orders o
  JOIN public.user_profiles up ON up.id = o.customer_id
  WHERE o.provider_id = p_provider_id
    AND COALESCE(up.taluka, '') <> ''
  GROUP BY up.taluka

  ORDER BY total_requests DESC;
END;
$$;
