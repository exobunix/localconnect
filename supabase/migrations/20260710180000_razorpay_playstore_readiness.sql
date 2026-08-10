-- ── Razorpay Play Store Readiness Migration ───────────────────────────────
-- Adds 'authorized' and 'refunded' statuses to the payment status enum
-- and ensures the razorpay-create-order edge function can pre-record orders.

-- Add 'authorized' value to enum if not present
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'authorized'
      AND enumtypid = 'public.razorpay_payment_status'::regtype
  ) THEN
    ALTER TYPE public.razorpay_payment_status ADD VALUE 'authorized';
  END IF;
END;
$$;

-- Add 'refund' payment type if not present
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum
    WHERE enumlabel = 'refund'
      AND enumtypid = 'public.razorpay_payment_type'::regtype
  ) THEN
    ALTER TYPE public.razorpay_payment_type ADD VALUE 'refund';
  END IF;
END;
$$;

-- ── Index for order lookup by razorpay_order_id ────────────────────────────
CREATE INDEX IF NOT EXISTS idx_razorpay_transactions_razorpay_order_id
  ON public.razorpay_transactions(razorpay_order_id)
  WHERE razorpay_order_id IS NOT NULL;

-- ── Index for pending transactions (for order creation pre-records) ────────
CREATE INDEX IF NOT EXISTS idx_razorpay_transactions_pending
  ON public.razorpay_transactions(status, created_at DESC)
  WHERE status = 'pending';
