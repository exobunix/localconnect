-- Migration: 20260829000003_admin_access_and_schema_fix.sql
-- Description: 
--   1. Reloads PostgREST schema cache (fixes categories 400 error)
--   2. Adds admin SELECT/ALL policies on service_providers, orders, complaints
--   3. Ensures admin@localconnect.com exists with correct credentials

-- ─── 1. Reload PostgREST schema cache ────────────────────────────────────────
NOTIFY pgrst, 'reload schema';

-- ─── 2. service_providers — Admin full access ─────────────────────────────────
DROP POLICY IF EXISTS "admin_select_all_providers" ON public.service_providers;
DROP POLICY IF EXISTS "admin_all_providers" ON public.service_providers;

CREATE POLICY "admin_all_providers"
  ON public.service_providers
  FOR ALL
  TO authenticated
  USING (
    public.is_admin_user()
    OR user_id = auth.uid()
    OR (is_active = true AND registration_status = 'approved')
  )
  WITH CHECK (
    public.is_admin_user()
    OR user_id = auth.uid()
  );

GRANT SELECT, INSERT, UPDATE ON public.service_providers TO authenticated;

-- ─── 3. orders — Admin full access ───────────────────────────────────────────
DROP POLICY IF EXISTS "admin_all_orders" ON public.orders;
DROP POLICY IF EXISTS "orders_select_own" ON public.orders;

CREATE POLICY "orders_select_own"
  ON public.orders
  FOR SELECT
  TO authenticated
  USING (
    public.is_admin_user()
    OR customer_id = auth.uid()
    OR provider_id IN (
      SELECT id FROM public.service_providers WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "admin_all_orders"
  ON public.orders
  FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

GRANT SELECT, INSERT, UPDATE ON public.orders TO authenticated;

-- ─── 4. complaints — Admin full access ───────────────────────────────────────
DROP POLICY IF EXISTS "Admin full access complaints" ON public.complaints;
DROP POLICY IF EXISTS "complaints_admin_all" ON public.complaints;

CREATE POLICY "complaints_admin_all"
  ON public.complaints
  FOR ALL
  TO authenticated
  USING (public.is_admin_user())
  WITH CHECK (public.is_admin_user());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.complaints TO authenticated;

-- ─── 5. user_profiles — Admin full read access ────────────────────────────────
DROP POLICY IF EXISTS "admin_read_all_profiles" ON public.user_profiles;

CREATE POLICY "admin_read_all_profiles"
  ON public.user_profiles
  FOR SELECT
  TO authenticated
  USING (
    public.is_admin_user()
    OR id = auth.uid()
  );

GRANT SELECT ON public.user_profiles TO authenticated;

-- ─── 6. Ensure admin user exists with correct credentials ─────────────────────
DO $$
DECLARE
  existing_id UUID;
BEGIN
  -- Find existing admin in auth.users
  SELECT id INTO existing_id
  FROM auth.users
  WHERE email = 'admin@localconnect.com'
  LIMIT 1;

  IF existing_id IS NULL THEN
    -- Create fresh admin user
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
      gen_random_uuid(),
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'admin@localconnect.com',
      crypt('Admin@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      '{"full_name": "Super Admin", "role": "admin"}'::jsonb,
      '{"provider": "email", "providers": ["email"]}'::jsonb,
      false, false, '', null, '', null, '', '', null, '', 0, '', null,
      null, '', '', null
    )
    RETURNING id INTO existing_id;

    RAISE NOTICE 'Created new admin user with id: %', existing_id;
  ELSE
    -- Reset password for existing admin
    UPDATE auth.users
    SET
      encrypted_password = crypt('Admin@1234', gen_salt('bf', 10)),
      email_confirmed_at = COALESCE(email_confirmed_at, now()),
      updated_at = now()
    WHERE id = existing_id;

    RAISE NOTICE 'Reset password for existing admin user id: %', existing_id;
  END IF;

  -- Upsert admin profile with role = 'admin'
  INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active, created_at, updated_at)
  VALUES (
    existing_id,
    'admin@localconnect.com',
    'Super Admin',
    '+919209205923',
    'admin',
    'Pune',
    true,
    now(),
    now()
  )
  ON CONFLICT (id) DO UPDATE
    SET role = 'admin',
        phone = COALESCE(public.user_profiles.phone, '+919209205923'),
        is_active = true,
        updated_at = now();

  RAISE NOTICE 'Admin user_profile upserted. Login: admin@localconnect.com / Admin@1234';
END $$;
