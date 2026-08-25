-- Account Deletion Audit Log
-- Tracks deletion events for compliance and audit purposes

CREATE TABLE IF NOT EXISTS public.account_deletion_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    user_email TEXT,
    user_role TEXT,
    deleted_at TIMESTAMPTZ DEFAULT NOW(),
    deletion_reason TEXT,
    ip_address TEXT,
    metadata JSONB DEFAULT '{}'::jsonb
);

CREATE INDEX IF NOT EXISTS idx_account_deletion_logs_user_id
    ON public.account_deletion_logs(user_id);

CREATE INDEX IF NOT EXISTS idx_account_deletion_logs_deleted_at
    ON public.account_deletion_logs(deleted_at);

ALTER TABLE public.account_deletion_logs ENABLE ROW LEVEL SECURITY;

-- Only service role can insert/read deletion logs (done via SECURITY DEFINER function)
DROP POLICY IF EXISTS "service_role_manage_deletion_logs" ON public.account_deletion_logs;
CREATE POLICY "service_role_manage_deletion_logs"
    ON public.account_deletion_logs
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Create a SECURITY DEFINER function to log deletion and delete user data
-- This runs with elevated privileges to clean up all user data
CREATE OR REPLACE FUNCTION public.delete_user_account(p_user_id UUID, p_user_email TEXT, p_user_role TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $func$
DECLARE
    v_result JSONB := '{}'::jsonb;
    v_provider_id UUID;
BEGIN
    -- 1. Log the deletion event first (audit trail)
    INSERT INTO public.account_deletion_logs (user_id, user_email, user_role, deletion_reason)
    VALUES (p_user_id, p_user_email, p_user_role, 'user_requested');

    -- 2. Get provider ID if provider role
    IF p_user_role = 'provider' THEN
        SELECT id INTO v_provider_id
        FROM public.service_providers
        WHERE user_id = p_user_id
        LIMIT 1;
    END IF;

    -- 3. Delete messages and conversations
    DELETE FROM public.messages
    WHERE sender_id = p_user_id;

    DELETE FROM public.conversations
    WHERE customer_id = p_user_id OR provider_id = p_user_id;

    -- 4. Delete notifications
    DELETE FROM public.notifications
    WHERE user_id = p_user_id;

    -- 5. Delete reviews
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'reviews') THEN
        DELETE FROM public.reviews WHERE customer_id = p_user_id;
    END IF;

    -- 6. Delete orders (customer)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'orders') THEN
        DELETE FROM public.orders WHERE customer_id = p_user_id;
    END IF;

    -- 7. Delete shop orders
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'shop_orders') THEN
        DELETE FROM public.shop_orders WHERE customer_id = p_user_id;
    END IF;

    -- 8. Delete provider-specific data if provider
    IF v_provider_id IS NOT NULL THEN
        -- Delete provider orders
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'orders') THEN
            DELETE FROM public.orders WHERE provider_id = v_provider_id;
        END IF;

        -- Delete provider subscriptions
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'provider_subscriptions') THEN
            DELETE FROM public.provider_subscriptions WHERE provider_id = v_provider_id;
        END IF;

        -- Delete earnings records
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'earnings_records') THEN
            DELETE FROM public.earnings_records WHERE provider_id = v_provider_id;
        END IF;

        -- Delete KYC documents
        IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'kyc_documents') THEN
            DELETE FROM public.kyc_documents WHERE provider_id = v_provider_id;
        END IF;

        -- Delete provider profile
        DELETE FROM public.service_providers WHERE id = v_provider_id;
    END IF;

    -- 9. Delete saved addresses
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'saved_addresses') THEN
        DELETE FROM public.saved_addresses WHERE user_id = p_user_id;
    END IF;

    -- 10. Delete payment methods
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'payment_methods') THEN
        DELETE FROM public.payment_methods WHERE user_id = p_user_id;
    END IF;

    -- 11. Delete support tickets / complaints
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'support_tickets') THEN
        DELETE FROM public.support_tickets WHERE user_id = p_user_id;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'complaints') THEN
        DELETE FROM public.complaints WHERE customer_id = p_user_id;
    END IF;

    -- 12. Delete razorpay transactions
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'razorpay_transactions') THEN
        DELETE FROM public.razorpay_transactions WHERE user_id = p_user_id;
    END IF;

    -- 13. Delete user profile (last before auth)
    DELETE FROM public.user_profiles WHERE id = p_user_id;

    v_result := jsonb_build_object('success', true, 'user_id', p_user_id::text);
    RETURN v_result;

EXCEPTION
    WHEN OTHERS THEN
        v_result := jsonb_build_object('success', false, 'error', SQLERRM);
        RETURN v_result;
END;
$func$;
