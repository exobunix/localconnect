-- ============================================================
-- Demo Provider Account Migration
-- Creates the demo.provider@localconnect.com auth account
-- used by the QA Testing Mode login bypass.
-- Safe to run multiple times (ON CONFLICT DO NOTHING).
-- ============================================================

DO $$
DECLARE
  demo_prov_auth_id  UUID := gen_random_uuid();
  demo_sp_id         UUID := gen_random_uuid();
  existing_auth_id   UUID;
  existing_sp_id     UUID;
BEGIN

  -- Check if the auth user already exists
  SELECT id INTO existing_auth_id
  FROM auth.users
  WHERE email = 'demo.provider@localconnect.com'
  LIMIT 1;

  IF existing_auth_id IS NULL THEN
    -- Insert the auth user
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
      demo_prov_auth_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'demo.provider@localconnect.com',
      crypt('DemoProvider@123', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'Demo Provider', 'role', 'provider'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null,
      null, '', '', null
    );

    -- Insert user_profile (trigger may or may not exist; upsert safely)
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (
      demo_prov_auth_id,
      'demo.provider@localconnect.com',
      'Demo Provider',
      '9000000001',
      'provider',
      'Pune',
      true
    )
    ON CONFLICT (email) DO NOTHING;

    -- Insert approved service_provider record
    INSERT INTO public.service_providers (
      id, user_id, business_name, owner_name, category, subcategory,
      description, phone, whatsapp, upi_id, address, city,
      rating, review_count, completed_orders, price_range,
      response_time, is_open, open_hours, today_offer,
      image_url, lat, lng, is_verified, is_active,
      member_since, onboarding_completed, earnings_total,
      accepted_orders, rejected_orders, registration_status
    ) VALUES (
      demo_sp_id,
      demo_prov_auth_id,
      'Demo Services', 'Demo Provider', 'Home Maintenance', 'General',
      'Demo provider account for QA testing. Pre-approved and ready to use.',
      '9000000001', '9000000001', 'demo.provider@upi',
      'Koregaon Park, Pune', 'Pune',
      4.8, 25, 30, '₹200 - ₹1000',
      '< 30 min', true, '8:00 AM - 8:00 PM', '10% off today',
      'https://images.pexels.com/photos/1216589/pexels-photo-1216589.jpeg',
      18.5362, 73.8938, true, true,
      'Jan 2026', true, 15000.00, 30, 2, 'approved'
    )
    ON CONFLICT (id) DO NOTHING;

    RAISE NOTICE 'Demo provider account created: demo.provider@localconnect.com';
  ELSE
    -- Account already exists — ensure the password is correct
    UPDATE auth.users
    SET encrypted_password = crypt('DemoProvider@123', gen_salt('bf', 10)),
        updated_at = now()
    WHERE id = existing_auth_id;

    -- Ensure service_provider record is approved
    UPDATE public.service_providers
    SET registration_status = 'approved', is_active = true
    WHERE user_id = existing_auth_id;

    RAISE NOTICE 'Demo provider account already exists — password reset and status confirmed approved.';
  END IF;

END $$;
