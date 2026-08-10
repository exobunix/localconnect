-- ─────────────────────────────────────────────────────────────────────────────
-- Fix: Service Request End-to-End Flow
-- Timestamp: 20260731091520
-- Changes:
--   1. Set REPLICA IDENTITY FULL on orders so Realtime filter on provider_id works
--   2. Ensure orders table is in supabase_realtime publication
--   3. Ensure orders RLS INSERT policy allows customer to insert with any provider_id
--   4. Add index on orders.provider_id for Realtime filter performance
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. REPLICA IDENTITY FULL on orders (required for Realtime column filters) ─
ALTER TABLE public.orders REPLICA IDENTITY FULL;

-- ── 2. Ensure orders is in supabase_realtime publication ─────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'orders'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
  END IF;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

-- ── 3. Ensure notifications is in supabase_realtime publication ──────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;

-- ── 4. Fix orders INSERT RLS: customer can insert order for any provider ──────
-- Drop old restrictive insert policy and recreate to allow provider_id to be set
DROP POLICY IF EXISTS "orders_insert_authenticated" ON public.orders;
CREATE POLICY "orders_insert_authenticated"
ON public.orders
FOR INSERT
TO authenticated
WITH CHECK (customer_id = auth.uid());

-- ── 5. Ensure index on provider_id exists for Realtime filter performance ─────
CREATE INDEX IF NOT EXISTS idx_orders_provider_id ON public.orders(provider_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
