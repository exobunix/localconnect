-- Migration: 20260829000003_reload_schema_and_fix_complaints_rls.sql
-- Description: Reloads PostgREST schema cache to make 'image_url' visible on categories, and fixes complaints RLS to use is_admin_user() function.

-- 1. Reload the schema cache for PostgREST
NOTIFY pgrst, 'reload schema';

-- 2. Drop old complaints policy and recreate with is_admin_user() to avoid RLS lookup recursion
DROP POLICY IF EXISTS "Admin full access complaints" ON public.complaints;
DROP POLICY IF EXISTS "complaints_admin_all" ON public.complaints;

CREATE POLICY "complaints_admin_all" ON public.complaints
  FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

-- Ensure permissions are set
GRANT SELECT, INSERT, UPDATE, DELETE ON public.complaints TO authenticated;

-- 3. Ensure admin user exists with correct password and admin role
DO $$
DECLARE
  admin_id UUID := 'd8b8a1c9-6c3f-4e8c-8f4b-74d32a106f2e';
  existing_id UUID;
BEGIN
  -- Check if admin user exists in auth.users
  SELECT id INTO existing_id FROM auth.users WHERE email = 'admin@localconnect.com' LIMIT 1;
  
  IF existing_id IS NULL THEN
    -- Insert admin user in auth.users
    INSERT INTO auth.users (
      id, instance_id, aud, role, email, encrypted_password,
      email_confirmed_at, created_at, updated_at,
      raw_user_meta_data, raw_app_meta_data,
      is_sso_user, is_anonymous,
      confirmation_token, confirmation_sent_at,
      recovery_token, recovery_sent_at,
      email_change_token_new, email_change, email_change_sent_at,
      email_change_token_current, email_change_confirm_status,
      reauthentication_token, reauthentication_sent_at,
      phone, phone_change, phone_change_token, phone_change_sent_at
    ) VALUES (
      admin_id, '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'admin@localconnect.com',
      crypt('Admin@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'Super Admin', 'role', 'admin'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );
    
    -- Insert profile in public.user_profiles
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (admin_id, 'admin@localconnect.com', 'Super Admin', '+919209205923', 'admin', 'Pune', true)
    ON CONFLICT (email) DO NOTHING;
  ELSE
    -- Reset password to Admin@1234 and ensure role is admin
    UPDATE auth.users 
    SET encrypted_password = crypt('Admin@1234', gen_salt('bf', 10)), 
        updated_at = now(),
        raw_user_meta_data = jsonb_build_object('full_name', 'Super Admin', 'role', 'admin')
    WHERE id = existing_id;
    
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (existing_id, 'admin@localconnect.com', 'Super Admin', '+919209205923', 'admin', 'Pune', true)
    ON CONFLICT (email) DO UPDATE 
    SET role = 'admin', phone = '+919209205923', updated_at = now();
    
    UPDATE public.user_profiles SET role = 'admin' WHERE id = existing_id;
  END IF;
END $$;
