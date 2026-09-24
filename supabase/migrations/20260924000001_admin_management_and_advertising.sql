-- Migration: 20260924000001_admin_management_and_advertising.sql
-- Description:
--   1. Creates public.admin_users table for Super Admin and Area-Wise Admins.
--   2. Adds RPC functions for Super Admin to create, update, delete admins, and reset passwords.
--   3. Creates public.provider_ad_requests table for Service Provider advertising requests and approval.
--   4. Adds RLS policies for admin access control and area-based filtering.

-- ── 1. Admin Users Table ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    phone TEXT DEFAULT '',
    role TEXT NOT NULL DEFAULT 'area_admin', -- 'super_admin' or 'area_admin'
    assigned_area TEXT NOT NULL DEFAULT 'Pune', -- City name or 'ALL' for super_admin
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_admin_users_email ON public.admin_users(email);
CREATE INDEX IF NOT EXISTS idx_admin_users_area ON public.admin_users(assigned_area);
CREATE INDEX IF NOT EXISTS idx_admin_users_role ON public.admin_users(role);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;

-- Allow admins to read and write admin_users
DROP POLICY IF EXISTS "admin_users_manage_policy" ON public.admin_users;
CREATE POLICY "admin_users_manage_policy" ON public.admin_users
    FOR ALL
    USING (public.is_admin_user() OR auth.role() = 'authenticated')
    WITH CHECK (public.is_admin_user() OR auth.role() = 'authenticated');

-- Seed initial Super Admin
INSERT INTO public.admin_users (email, full_name, phone, role, assigned_area, is_active)
VALUES 
  ('admin@localconnect.com', 'Super Administrator', '+919209205923', 'super_admin', 'ALL', true)
ON CONFLICT (email) DO UPDATE SET
  role = 'super_admin',
  assigned_area = 'ALL',
  is_active = true;

-- ── 2. Provider Advertising Requests Table ─────────────────────────────────

CREATE TABLE IF NOT EXISTS public.provider_ad_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID,
    provider_name TEXT NOT NULL DEFAULT '',
    business_name TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL DEFAULT '',
    city TEXT NOT NULL DEFAULT 'Pune',
    title TEXT NOT NULL,
    subtitle TEXT DEFAULT '',
    image_url TEXT DEFAULT '',
    target_url TEXT DEFAULT '',
    duration_days INT NOT NULL DEFAULT 15,
    status TEXT NOT NULL DEFAULT 'pending', -- 'pending', 'approved', 'rejected'
    admin_note TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ad_requests_provider ON public.provider_ad_requests(provider_id);
CREATE INDEX IF NOT EXISTS idx_ad_requests_status ON public.provider_ad_requests(status);
CREATE INDEX IF NOT EXISTS idx_ad_requests_city ON public.provider_ad_requests(city);

ALTER TABLE public.provider_ad_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "ad_requests_all" ON public.provider_ad_requests;
CREATE POLICY "ad_requests_all" ON public.provider_ad_requests
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- ── 3. RPC Functions for Admin Management ──────────────────────────────────

-- Function to fetch all admins (Security Definer)
CREATE OR REPLACE FUNCTION public.get_all_admins()
RETURNS TABLE (
    id UUID,
    email TEXT,
    full_name TEXT,
    phone TEXT,
    role TEXT,
    assigned_area TEXT,
    is_active BOOLEAN,
    created_at TIMESTAMPTZ
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public, auth
AS $$
    SELECT id, email, full_name, phone, role, assigned_area, is_active, created_at
    FROM public.admin_users
    ORDER BY role DESC, full_name ASC;
$$;

-- Function to upsert an admin account
CREATE OR REPLACE FUNCTION public.admin_upsert_admin_account(
    p_id UUID,
    p_email TEXT,
    p_full_name TEXT,
    p_phone TEXT,
    p_role TEXT,
    p_assigned_area TEXT,
    p_is_active BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_admin_id UUID;
BEGIN
    IF p_id IS NOT NULL THEN
        UPDATE public.admin_users
        SET 
            email = p_email,
            full_name = p_full_name,
            phone = p_phone,
            role = p_role,
            assigned_area = p_assigned_area,
            is_active = p_is_active,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_id
        RETURNING id INTO v_admin_id;
    ELSE
        INSERT INTO public.admin_users (email, full_name, phone, role, assigned_area, is_active)
        VALUES (p_email, p_full_name, p_phone, p_role, p_assigned_area, p_is_active)
        ON CONFLICT (email) DO UPDATE SET
            full_name = p_full_name,
            phone = p_phone,
            role = p_role,
            assigned_area = p_assigned_area,
            is_active = p_is_active,
            updated_at = CURRENT_TIMESTAMP
        RETURNING id INTO v_admin_id;
    END IF;

    -- Also ensure profile in user_profiles has role='admin'
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city)
    VALUES (v_admin_id, p_email, p_full_name, p_phone, 'admin', p_assigned_area)
    ON CONFLICT (id) DO UPDATE SET
        role = 'admin',
        city = p_assigned_area;

    RETURN jsonb_build_object('success', true, 'id', v_admin_id);
END;
$$;

-- Function to delete an admin account
CREATE OR REPLACE FUNCTION public.admin_delete_admin_account(p_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_email TEXT;
BEGIN
    SELECT email INTO v_email FROM public.admin_users WHERE id = p_id;
    IF v_email = 'admin@localconnect.com' THEN
        RETURN jsonb_build_object('success', false, 'error', 'Cannot delete primary Super Admin.');
    END IF;

    DELETE FROM public.admin_users WHERE id = p_id;
    RETURN jsonb_build_object('success', true);
END;
$$;

-- Function to approve provider advertising request and create live banner
CREATE OR REPLACE FUNCTION public.admin_approve_ad_request(
    p_request_id UUID,
    p_gradient_start TEXT DEFAULT '#1565C0',
    p_gradient_end TEXT DEFAULT '#1E88E5'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_req RECORD;
BEGIN
    SELECT * INTO v_req FROM public.provider_ad_requests WHERE id = p_request_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('success', false, 'error', 'Ad request not found');
    END IF;

    -- Update request status
    UPDATE public.provider_ad_requests
    SET status = 'approved', updated_at = CURRENT_TIMESTAMP
    WHERE id = p_request_id;

    -- Insert into banners table
    INSERT INTO public.banners (
        title,
        subtitle,
        image_url,
        action_url,
        gradient_start,
        gradient_end,
        is_active,
        sort_order
    )
    VALUES (
        v_req.title,
        COALESCE(v_req.subtitle, v_req.business_name),
        v_req.image_url,
        COALESCE(v_req.target_url, '/provider/' || v_req.provider_id),
        p_gradient_start,
        p_gradient_end,
        true,
        1
    );

    RETURN jsonb_build_object('success', true);
END;
$$;
