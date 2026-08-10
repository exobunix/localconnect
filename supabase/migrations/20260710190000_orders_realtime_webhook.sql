-- ── Orders Realtime + Webhook Lookup Support ──────────────────────────────
-- Enables Supabase Realtime on orders table so Flutter receives live
-- payment_status changes pushed by the razorpay-webhook Edge Function.
-- Also ensures razorpay_order_id index exists for fast webhook lookups.

-- ── Ensure razorpay_order_id column exists on orders (idempotent) ─────────
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS razorpay_order_id TEXT;

-- ── Index for webhook lookup: orders.razorpay_order_id ────────────────────
CREATE INDEX IF NOT EXISTS idx_orders_razorpay_order_id_webhook
  ON public.orders(razorpay_order_id)
  WHERE razorpay_order_id IS NOT NULL;

-- ── Enable Realtime publication for orders table ───────────────────────────
-- This allows Flutter Supabase client to subscribe to payment_status changes
-- in real-time via supabase.from('orders').stream() or .on('UPDATE', ...)
ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;

-- ── Ensure updated_at column exists on orders (required for webhook update) ─
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP;

-- ── Trigger to auto-update updated_at on orders ───────────────────────────
CREATE OR REPLACE FUNCTION public.update_orders_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_orders_updated_at ON public.orders;
CREATE TRIGGER trg_orders_updated_at
BEFORE UPDATE ON public.orders
FOR EACH ROW EXECUTE FUNCTION public.update_orders_updated_at();

-- ── RLS: service_role can update orders (used by webhook Edge Function) ────
DROP POLICY IF EXISTS "service_role_update_orders_payment_status" ON public.orders;
CREATE POLICY "service_role_update_orders_payment_status"
ON public.orders
FOR UPDATE
TO service_role
USING (true)
WITH CHECK (true);
