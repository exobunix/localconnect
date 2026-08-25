-- ── Orders Payment Status Columns ─────────────────────────────────────────
-- Adds payment_status and razorpay_payment_id to orders table
-- so Razorpay checkout results are stored alongside each booking.

ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS payment_status TEXT NOT NULL DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS razorpay_payment_id TEXT,
  ADD COLUMN IF NOT EXISTS razorpay_order_id TEXT,
  ADD COLUMN IF NOT EXISTS payment_method TEXT DEFAULT 'cash',
  ADD COLUMN IF NOT EXISTS amount_paid DECIMAL(10,2);

-- ── Index for payment status queries ──────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_orders_payment_status
  ON public.orders(payment_status);

CREATE INDEX IF NOT EXISTS idx_orders_razorpay_payment_id
  ON public.orders(razorpay_payment_id)
  WHERE razorpay_payment_id IS NOT NULL;

-- ── Backfill existing orders: cash/upi orders are considered paid ──────────
UPDATE public.orders
SET payment_status = CASE
  WHEN status = 'completed' THEN 'paid'
  WHEN status = 'cancelled' THEN 'refunded'
  ELSE 'pending'
END
WHERE payment_status = 'pending';
