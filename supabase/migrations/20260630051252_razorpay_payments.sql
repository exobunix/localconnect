-- Razorpay Payments Integration Migration
-- Tracks one-time payments and subscription payments via Razorpay

-- ── Payment status type ────────────────────────────────────────────────────
DROP TYPE IF EXISTS public.razorpay_payment_status CASCADE;
CREATE TYPE public.razorpay_payment_status AS ENUM ('pending', 'success', 'failed', 'refunded');

DROP TYPE IF EXISTS public.razorpay_payment_type CASCADE;
CREATE TYPE public.razorpay_payment_type AS ENUM ('one_time', 'subscription');

-- ── Razorpay transactions table ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.razorpay_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
    razorpay_order_id TEXT,
    razorpay_payment_id TEXT,
    razorpay_signature TEXT,
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'INR',
    payment_type public.razorpay_payment_type NOT NULL DEFAULT 'one_time',
    status public.razorpay_payment_status NOT NULL DEFAULT 'pending',
    description TEXT,
    order_id UUID,
    provider_id UUID,
    plan_id UUID,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ── Indexes ────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_razorpay_transactions_user_id ON public.razorpay_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_razorpay_transactions_status ON public.razorpay_transactions(status);
CREATE INDEX IF NOT EXISTS idx_razorpay_transactions_payment_id ON public.razorpay_transactions(razorpay_payment_id);
CREATE INDEX IF NOT EXISTS idx_razorpay_transactions_order_id ON public.razorpay_transactions(order_id);
CREATE INDEX IF NOT EXISTS idx_razorpay_transactions_created_at ON public.razorpay_transactions(created_at DESC);

-- ── Enable RLS ─────────────────────────────────────────────────────────────
ALTER TABLE public.razorpay_transactions ENABLE ROW LEVEL SECURITY;

-- ── RLS Policies ──────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "users_view_own_razorpay_transactions" ON public.razorpay_transactions;
CREATE POLICY "users_view_own_razorpay_transactions"
ON public.razorpay_transactions
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "users_insert_own_razorpay_transactions" ON public.razorpay_transactions;
CREATE POLICY "users_insert_own_razorpay_transactions"
ON public.razorpay_transactions
FOR INSERT
TO authenticated
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_update_own_razorpay_transactions" ON public.razorpay_transactions;
CREATE POLICY "users_update_own_razorpay_transactions"
ON public.razorpay_transactions
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Admin can view all transactions
DROP POLICY IF EXISTS "admin_all_razorpay_transactions" ON public.razorpay_transactions;
CREATE POLICY "admin_all_razorpay_transactions"
ON public.razorpay_transactions
FOR ALL
TO authenticated
USING (public.is_admin_user())
WITH CHECK (public.is_admin_user());

-- ── Updated at trigger ─────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_razorpay_transaction_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_razorpay_transactions_updated_at ON public.razorpay_transactions;
CREATE TRIGGER trg_razorpay_transactions_updated_at
BEFORE UPDATE ON public.razorpay_transactions
FOR EACH ROW EXECUTE FUNCTION public.update_razorpay_transaction_updated_at();
