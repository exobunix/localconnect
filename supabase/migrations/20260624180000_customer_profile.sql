-- Customer Profile: saved addresses, payment methods, preferences
-- Timestamp: 20260624180000 (higher than existing 20260624170000)

-- ─── SAVED ADDRESSES ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.saved_addresses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    label TEXT NOT NULL DEFAULT 'Home',
    address_line1 TEXT NOT NULL,
    address_line2 TEXT,
    city TEXT NOT NULL,
    state TEXT NOT NULL DEFAULT 'Maharashtra',
    pincode TEXT NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_saved_addresses_user_id ON public.saved_addresses(user_id);

-- ─── PAYMENT METHODS ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.payment_methods (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    label TEXT NOT NULL,
    details JSONB NOT NULL DEFAULT '{}',
    is_default BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_payment_methods_user_id ON public.payment_methods(user_id);

-- ─── ORDER PREFERENCES ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.order_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    preferred_time_slot TEXT DEFAULT 'morning',
    preferred_payment_type TEXT DEFAULT 'cash',
    auto_reorder BOOLEAN NOT NULL DEFAULT false,
    notify_offers BOOLEAN NOT NULL DEFAULT true,
    notify_order_updates BOOLEAN NOT NULL DEFAULT true,
    notify_messages BOOLEAN NOT NULL DEFAULT true,
    language TEXT NOT NULL DEFAULT 'en',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_order_preferences_user_id ON public.order_preferences(user_id);

-- ─── ENABLE RLS ───────────────────────────────────────────────────────────────
ALTER TABLE public.saved_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_preferences ENABLE ROW LEVEL SECURITY;

-- ─── RLS POLICIES ─────────────────────────────────────────────────────────────
DROP POLICY IF EXISTS "users_manage_own_saved_addresses" ON public.saved_addresses;
CREATE POLICY "users_manage_own_saved_addresses"
ON public.saved_addresses FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_payment_methods" ON public.payment_methods;
CREATE POLICY "users_manage_own_payment_methods"
ON public.payment_methods FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "users_manage_own_order_preferences" ON public.order_preferences;
CREATE POLICY "users_manage_own_order_preferences"
ON public.order_preferences FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ─── PHONE COLUMN ON USER_PROFILES (if not exists) ────────────────────────────
ALTER TABLE public.user_profiles
ADD COLUMN IF NOT EXISTS phone TEXT DEFAULT '';

-- ─── MOCK DATA ────────────────────────────────────────────────────────────────
DO $$
DECLARE
    existing_user_id UUID;
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'user_profiles'
    ) THEN
        SELECT id INTO existing_user_id FROM public.user_profiles LIMIT 1;

        IF existing_user_id IS NOT NULL THEN
            INSERT INTO public.saved_addresses (user_id, label, address_line1, city, state, pincode, is_default)
            VALUES
                (existing_user_id, 'Home', '12, Shivaji Nagar', 'Pune', 'Maharashtra', '411005', true),
                (existing_user_id, 'Work', '3rd Floor, Hinjewadi IT Park', 'Pune', 'Maharashtra', '411057', false)
            ON CONFLICT (id) DO NOTHING;

            INSERT INTO public.payment_methods (user_id, type, label, details, is_default)
            VALUES
                (existing_user_id, 'upi', 'UPI', jsonb_build_object('upi_id', 'user@upi'), true),
                (existing_user_id, 'cash', 'Cash on Delivery', jsonb_build_object(), false)
            ON CONFLICT (id) DO NOTHING;

            INSERT INTO public.order_preferences (user_id, preferred_time_slot, preferred_payment_type, auto_reorder, notify_offers, notify_order_updates, notify_messages, language)
            VALUES (existing_user_id, 'morning', 'upi', false, true, true, true, 'en')
            ON CONFLICT (user_id) DO NOTHING;
        ELSE
            RAISE NOTICE 'No existing users found. Skipping mock data.';
        END IF;
    ELSE
        RAISE NOTICE 'Table user_profiles does not exist. Skipping mock data.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;
