-- Provider Dashboard Migration
-- Adds RLS policies for providers to manage their orders
-- and an earnings_total column to service_providers

-- Add earnings_total column to service_providers if not exists
ALTER TABLE public.service_providers
ADD COLUMN IF NOT EXISTS earnings_total NUMERIC DEFAULT 0.0;

-- Add accepted_orders column for tracking
ALTER TABLE public.service_providers
ADD COLUMN IF NOT EXISTS accepted_orders INTEGER DEFAULT 0;

ALTER TABLE public.service_providers
ADD COLUMN IF NOT EXISTS rejected_orders INTEGER DEFAULT 0;

-- ─── RLS POLICIES FOR ORDERS (PROVIDER ACCESS) ──────────────────────────────

-- Allow providers to view orders assigned to their service_provider record
DROP POLICY IF EXISTS "providers_view_own_orders" ON public.orders;
CREATE POLICY "providers_view_own_orders"
ON public.orders
FOR SELECT
TO authenticated
USING (
  provider_id IN (
    SELECT id FROM public.service_providers WHERE user_id = auth.uid()
  )
);

-- Allow providers to update status of their own orders
DROP POLICY IF EXISTS "providers_update_own_orders" ON public.orders;
CREATE POLICY "providers_update_own_orders"
ON public.orders
FOR UPDATE
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

-- Allow providers to update their own service_providers record (earnings, counts)
DROP POLICY IF EXISTS "providers_update_own_provider_record" ON public.service_providers;
CREATE POLICY "providers_update_own_provider_record"
ON public.service_providers
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Indexes for provider dashboard queries
CREATE INDEX IF NOT EXISTS idx_orders_provider_id ON public.orders(provider_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_service_providers_user_id ON public.service_providers(user_id);
