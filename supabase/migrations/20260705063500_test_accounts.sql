-- ============================================================
-- Test Accounts Migration
-- Creates ready-to-use test accounts for QA testing:
--   Admin, Customer, and Providers for each subcategory
-- Safe to run multiple times (ON CONFLICT DO NOTHING).
-- ============================================================

DO $$
DECLARE
  -- Admin
  admin_auth_id       UUID := gen_random_uuid();

  -- Customer
  cust_auth_id        UUID := gen_random_uuid();

  -- Home Maintenance Providers
  plumber_auth_id     UUID := gen_random_uuid();
  electrician_auth_id UUID := gen_random_uuid();
  carpenter_auth_id   UUID := gen_random_uuid();
  painter_auth_id     UUID := gen_random_uuid();
  mason_auth_id       UUID := gen_random_uuid();
  cleaner_auth_id     UUID := gen_random_uuid();
  dailywage_auth_id   UUID := gen_random_uuid();

  -- Transport Providers
  ride_auth_id        UUID := gen_random_uuid();
  goods_auth_id       UUID := gen_random_uuid();

  -- Event Management Providers
  photo_auth_id       UUID := gen_random_uuid();
  deco_auth_id        UUID := gen_random_uuid();
  sound_auth_id       UUID := gen_random_uuid();
  makeup_auth_id      UUID := gen_random_uuid();

  -- service_provider row IDs
  sp_plumber_id     UUID := gen_random_uuid();
  sp_elec_id        UUID := gen_random_uuid();
  sp_carp_id        UUID := gen_random_uuid();
  sp_paint_id       UUID := gen_random_uuid();
  sp_mason_id       UUID := gen_random_uuid();
  sp_clean_id       UUID := gen_random_uuid();
  sp_daily_id       UUID := gen_random_uuid();
  sp_ride_id        UUID := gen_random_uuid();
  sp_goods_id       UUID := gen_random_uuid();
  sp_photo_id       UUID := gen_random_uuid();
  sp_deco_id        UUID := gen_random_uuid();
  sp_sound_id       UUID := gen_random_uuid();
  sp_makeup_id      UUID := gen_random_uuid();

  existing_id UUID;
BEGIN

  -- ── ADMIN ──────────────────────────────────────────────────
  SELECT id INTO existing_id FROM auth.users WHERE email = 'admin@localconnect.com' LIMIT 1;
  IF existing_id IS NULL THEN
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
      admin_auth_id, '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'admin@localconnect.com',
      crypt('Admin@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'Super Admin', 'role', 'admin'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (admin_auth_id, 'admin@localconnect.com', 'Super Admin', '9000000000', 'admin', 'Pune', true)
    ON CONFLICT (email) DO NOTHING;
    RAISE NOTICE 'Admin account created: admin@localconnect.com';
  ELSE
    UPDATE auth.users SET encrypted_password = crypt('Admin@1234', gen_salt('bf', 10)), updated_at = now() WHERE id = existing_id;
    UPDATE public.user_profiles SET role = 'admin' WHERE id = existing_id;
    RAISE NOTICE 'Admin account already exists — password reset.';
  END IF;

  -- ── CUSTOMER ───────────────────────────────────────────────
  SELECT id INTO existing_id FROM auth.users WHERE email = 'customer@localconnect.com' LIMIT 1;
  IF existing_id IS NULL THEN
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
      cust_auth_id, '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'customer@localconnect.com',
      crypt('Customer@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'Test Customer', 'role', 'customer'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (cust_auth_id, 'customer@localconnect.com', 'Test Customer', '9000000010', 'customer', 'Pune', true)
    ON CONFLICT (email) DO NOTHING;
    RAISE NOTICE 'Customer account created: customer@localconnect.com';
  ELSE
    UPDATE auth.users SET encrypted_password = crypt('Customer@1234', gen_salt('bf', 10)), updated_at = now() WHERE id = existing_id;
    RAISE NOTICE 'Customer account already exists — password reset.';
  END IF;

  -- ── HOME MAINTENANCE: PLUMBER ──────────────────────────────
  SELECT id INTO existing_id FROM auth.users WHERE email = 'plumber@localconnect.com' LIMIT 1;
  IF existing_id IS NULL THEN
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
      plumber_auth_id, '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'plumber@localconnect.com',
      crypt('Provider@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'Ramesh Plumber', 'role', 'provider'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (plumber_auth_id, 'plumber@localconnect.com', 'Ramesh Plumber', '9000000011', 'provider', 'Pune', true)
    ON CONFLICT (email) DO NOTHING;
    INSERT INTO public.service_providers (
      id, user_id, business_name, owner_name, category, subcategory,
      description, phone, whatsapp, upi_id, address, city,
      rating, review_count, completed_orders, price_range,
      response_time, is_open, open_hours, today_offer,
      image_url, lat, lng, is_verified, is_active,
      member_since, onboarding_completed, earnings_total,
      accepted_orders, rejected_orders, registration_status
    ) VALUES (
      sp_plumber_id, plumber_auth_id,
      'Ramesh Plumbing Works', 'Ramesh Plumber', 'Home Maintenance', 'Plumber',
      'Expert plumbing services including pipe repairs, bathroom fittings, and leak fixes.',
      '9000000011', '9000000011', 'ramesh.plumber@upi',
      'Kothrud, Pune', 'Pune',
      4.6, 32, 45, '200 - 800',
      '< 30 min', true, '8:00 AM - 7:00 PM', '10% off today',
      'https://images.pexels.com/photos/1216589/pexels-photo-1216589.jpeg',
      18.5074, 73.8077, true, true,
      'Jan 2025', true, 22500.00, 45, 2, 'approved'
    ) ON CONFLICT (id) DO NOTHING;
    RAISE NOTICE 'Plumber provider created: plumber@localconnect.com';
  ELSE
    UPDATE auth.users SET encrypted_password = crypt('Provider@1234', gen_salt('bf', 10)), updated_at = now() WHERE id = existing_id;
    UPDATE public.service_providers SET registration_status = 'approved', is_active = true WHERE user_id = existing_id;
    RAISE NOTICE 'Plumber account already exists — password reset.';
  END IF;

  -- ── HOME MAINTENANCE: ELECTRICIAN ─────────────────────────
  SELECT id INTO existing_id FROM auth.users WHERE email = 'electrician@localconnect.com' LIMIT 1;
  IF existing_id IS NULL THEN
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
      electrician_auth_id, '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'electrician@localconnect.com',
      crypt('Provider@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'Vijay Electrician', 'role', 'provider'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (electrician_auth_id, 'electrician@localconnect.com', 'Vijay Electrician', '9000000012', 'provider', 'Pune', true)
    ON CONFLICT (email) DO NOTHING;
    INSERT INTO public.service_providers (
      id, user_id, business_name, owner_name, category, subcategory,
      description, phone, whatsapp, upi_id, address, city,
      rating, review_count, completed_orders, price_range,
      response_time, is_open, open_hours, today_offer,
      image_url, lat, lng, is_verified, is_active,
      member_since, onboarding_completed, earnings_total,
      accepted_orders, rejected_orders, registration_status
    ) VALUES (
      sp_elec_id, electrician_auth_id,
      'Vijay Electrical Services', 'Vijay Electrician', 'Home Maintenance', 'Electrician',
      'Licensed electrician for wiring, fan/AC installation, and appliance repairs.',
      '9000000012', '9000000012', 'vijay.electric@upi',
      'Wakad, Pune', 'Pune',
      4.7, 28, 38, '300 - 1500',
      '< 45 min', true, '8:30 AM - 6:30 PM', 'Free inspection today',
      'https://images.pexels.com/photos/257736/pexels-photo-257736.jpeg',
      18.5975, 73.7898, true, true,
      'Feb 2025', true, 19000.00, 38, 3, 'approved'
    ) ON CONFLICT (id) DO NOTHING;
    RAISE NOTICE 'Electrician provider created: electrician@localconnect.com';
  ELSE
    UPDATE auth.users SET encrypted_password = crypt('Provider@1234', gen_salt('bf', 10)), updated_at = now() WHERE id = existing_id;
    UPDATE public.service_providers SET registration_status = 'approved', is_active = true WHERE user_id = existing_id;
    RAISE NOTICE 'Electrician account already exists — password reset.';
  END IF;

  -- ── HOME MAINTENANCE: CARPENTER ───────────────────────────
  SELECT id INTO existing_id FROM auth.users WHERE email = 'carpenter@localconnect.com' LIMIT 1;
  IF existing_id IS NULL THEN
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
      carpenter_auth_id, '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'carpenter@localconnect.com',
      crypt('Provider@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'Sunil Carpenter', 'role', 'provider'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (carpenter_auth_id, 'carpenter@localconnect.com', 'Sunil Carpenter', '9000000013', 'provider', 'Pune', true)
    ON CONFLICT (email) DO NOTHING;
    INSERT INTO public.service_providers (
      id, user_id, business_name, owner_name, category, subcategory,
      description, phone, whatsapp, upi_id, address, city,
      rating, review_count, completed_orders, price_range,
      response_time, is_open, open_hours, today_offer,
      image_url, lat, lng, is_verified, is_active,
      member_since, onboarding_completed, earnings_total,
      accepted_orders, rejected_orders, registration_status
    ) VALUES (
      sp_carp_id, carpenter_auth_id,
      'Sunil Carpentry Works', 'Sunil Carpenter', 'Home Maintenance', 'Carpenter',
      'Custom furniture, door/window repairs, and woodwork installations.',
      '9000000013', '9000000013', 'sunil.carpenter@upi',
      'Hadapsar, Pune', 'Pune',
      4.5, 20, 30, '500 - 3000',
      '< 60 min', true, '9:00 AM - 6:00 PM', 'Free measurement visit',
      'https://images.pexels.com/photos/1249611/pexels-photo-1249611.jpeg',
      18.5089, 73.9259, true, true,
      'Mar 2025', true, 15000.00, 30, 2, 'approved'
    ) ON CONFLICT (id) DO NOTHING;
    RAISE NOTICE 'Carpenter provider created: carpenter@localconnect.com';
  ELSE
    UPDATE auth.users SET encrypted_password = crypt('Provider@1234', gen_salt('bf', 10)), updated_at = now() WHERE id = existing_id;
    UPDATE public.service_providers SET registration_status = 'approved', is_active = true WHERE user_id = existing_id;
    RAISE NOTICE 'Carpenter account already exists — password reset.';
  END IF;

  -- ── HOME MAINTENANCE: PAINTER ──────────────────────────────
  SELECT id INTO existing_id FROM auth.users WHERE email = 'painter@localconnect.com' LIMIT 1;
  IF existing_id IS NULL THEN
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
      painter_auth_id, '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'painter@localconnect.com',
      crypt('Provider@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'Anil Painter', 'role', 'provider'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (painter_auth_id, 'painter@localconnect.com', 'Anil Painter', '9000000014', 'provider', 'Pune', true)
    ON CONFLICT (email) DO NOTHING;
    INSERT INTO public.service_providers (
      id, user_id, business_name, owner_name, category, subcategory,
      description, phone, whatsapp, upi_id, address, city,
      rating, review_count, completed_orders, price_range,
      response_time, is_open, open_hours, today_offer,
      image_url, lat, lng, is_verified, is_active,
      member_since, onboarding_completed, earnings_total,
      accepted_orders, rejected_orders, registration_status
    ) VALUES (
      sp_paint_id, painter_auth_id,
      'Anil Painting Services', 'Anil Painter', 'Home Maintenance', 'Painter',
      'Interior and exterior painting with premium quality paints and clean finish.',
      '9000000014', '9000000014', 'anil.painter@upi',
      'Baner, Pune', 'Pune',
      4.4, 18, 25, '1000 - 8000',
      '< 2 hours', true, '8:00 AM - 5:00 PM', 'Free colour consultation',
      'https://images.pexels.com/photos/1669754/pexels-photo-1669754.jpeg',
      18.5590, 73.7868, true, true,
      'Apr 2025', true, 12500.00, 25, 1, 'approved'
    ) ON CONFLICT (id) DO NOTHING;
    RAISE NOTICE 'Painter provider created: painter@localconnect.com';
  ELSE
    UPDATE auth.users SET encrypted_password = crypt('Provider@1234', gen_salt('bf', 10)), updated_at = now() WHERE id = existing_id;
    UPDATE public.service_providers SET registration_status = 'approved', is_active = true WHERE user_id = existing_id;
    RAISE NOTICE 'Painter account already exists — password reset.';
  END IF;

  -- ── HOME MAINTENANCE: MASON ────────────────────────────────
  SELECT id INTO existing_id FROM auth.users WHERE email = 'mason@localconnect.com' LIMIT 1;
  IF existing_id IS NULL THEN
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
      mason_auth_id, '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'mason@localconnect.com',
      crypt('Provider@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'Ganesh Mason', 'role', 'provider'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (mason_auth_id, 'mason@localconnect.com', 'Ganesh Mason', '9000000015', 'provider', 'Pune', true)
    ON CONFLICT (email) DO NOTHING;
    INSERT INTO public.service_providers (
      id, user_id, business_name, owner_name, category, subcategory,
      description, phone, whatsapp, upi_id, address, city,
      rating, review_count, completed_orders, price_range,
      response_time, is_open, open_hours, today_offer,
      image_url, lat, lng, is_verified, is_active,
      member_since, onboarding_completed, earnings_total,
      accepted_orders, rejected_orders, registration_status
    ) VALUES (
      sp_mason_id, mason_auth_id,
      'Ganesh Masonry Works', 'Ganesh Mason', 'Home Maintenance', 'Mason',
      'Brick laying, plastering, tiling, and civil construction work.',
      '9000000015', '9000000015', 'ganesh.mason@upi',
      'Kondhwa, Pune', 'Pune',
      4.3, 15, 20, '800 - 5000',
      '< 2 hours', true, '8:00 AM - 5:00 PM', 'Free site visit',
      'https://images.pexels.com/photos/585419/pexels-photo-585419.jpeg',
      18.4529, 73.8778, true, true,
      'May 2025', true, 10000.00, 20, 1, 'approved'
    ) ON CONFLICT (id) DO NOTHING;
    RAISE NOTICE 'Mason provider created: mason@localconnect.com';
  ELSE
    UPDATE auth.users SET encrypted_password = crypt('Provider@1234', gen_salt('bf', 10)), updated_at = now() WHERE id = existing_id;
    UPDATE public.service_providers SET registration_status = 'approved', is_active = true WHERE user_id = existing_id;
    RAISE NOTICE 'Mason account already exists — password reset.';
  END IF;

  -- ── HOME MAINTENANCE: CLEANING ─────────────────────────────
  SELECT id INTO existing_id FROM auth.users WHERE email = 'cleaning@localconnect.com' LIMIT 1;
  IF existing_id IS NULL THEN
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
      cleaner_auth_id, '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'cleaning@localconnect.com',
      crypt('Provider@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'Sunita Cleaning', 'role', 'provider'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (cleaner_auth_id, 'cleaning@localconnect.com', 'Sunita Cleaning', '9000000016', 'provider', 'Pune', true)
    ON CONFLICT (email) DO NOTHING;
    INSERT INTO public.service_providers (
      id, user_id, business_name, owner_name, category, subcategory,
      description, phone, whatsapp, upi_id, address, city,
      rating, review_count, completed_orders, price_range,
      response_time, is_open, open_hours, today_offer,
      image_url, lat, lng, is_verified, is_active,
      member_since, onboarding_completed, earnings_total,
      accepted_orders, rejected_orders, registration_status
    ) VALUES (
      sp_clean_id, cleaner_auth_id,
      'Sunita Home Cleaning', 'Sunita Cleaning', 'Home Maintenance', 'Cleaning',
      'Deep cleaning, bathroom cleaning, kitchen cleaning, and sofa/carpet cleaning.',
      '9000000016', '9000000016', 'sunita.cleaning@upi',
      'Aundh, Pune', 'Pune',
      4.8, 42, 60, '400 - 2000',
      '< 30 min', true, '7:00 AM - 7:00 PM', 'Bathroom free with kitchen cleaning',
      'https://images.pexels.com/photos/4107120/pexels-photo-4107120.jpeg',
      18.5642, 73.8077, true, true,
      'Jan 2025', true, 30000.00, 60, 2, 'approved'
    ) ON CONFLICT (id) DO NOTHING;
    RAISE NOTICE 'Cleaning provider created: cleaning@localconnect.com';
  ELSE
    UPDATE auth.users SET encrypted_password = crypt('Provider@1234', gen_salt('bf', 10)), updated_at = now() WHERE id = existing_id;
    UPDATE public.service_providers SET registration_status = 'approved', is_active = true WHERE user_id = existing_id;
    RAISE NOTICE 'Cleaning account already exists — password reset.';
  END IF;

  -- ── HOME MAINTENANCE: DAILY WAGE ───────────────────────────
  SELECT id INTO existing_id FROM auth.users WHERE email = 'dailywage@localconnect.com' LIMIT 1;
  IF existing_id IS NULL THEN
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
      dailywage_auth_id, '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'dailywage@localconnect.com',
      crypt('Provider@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'Raju Daily Worker', 'role', 'provider'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (dailywage_auth_id, 'dailywage@localconnect.com', 'Raju Daily Worker', '9000000017', 'provider', 'Pune', true)
    ON CONFLICT (email) DO NOTHING;
    INSERT INTO public.service_providers (
      id, user_id, business_name, owner_name, category, subcategory,
      description, phone, whatsapp, upi_id, address, city,
      rating, review_count, completed_orders, price_range,
      response_time, is_open, open_hours, today_offer,
      image_url, lat, lng, is_verified, is_active,
      member_since, onboarding_completed, earnings_total,
      accepted_orders, rejected_orders, registration_status
    ) VALUES (
      sp_daily_id, dailywage_auth_id,
      'Raju General Labour', 'Raju Daily Worker', 'Home Maintenance', 'Daily Wage',
      'General labour work including loading, shifting, digging, and helper tasks.',
      '9000000017', '9000000017', 'raju.daily@upi',
      'Yerawada, Pune', 'Pune',
      4.2, 12, 18, '300 - 600',
      '< 1 hour', true, '7:00 AM - 6:00 PM', 'Available today',
      'https://images.pexels.com/photos/1216589/pexels-photo-1216589.jpeg',
      18.5531, 73.8937, true, true,
      'Jun 2025', true, 5400.00, 18, 1, 'approved'
    ) ON CONFLICT (id) DO NOTHING;
    RAISE NOTICE 'Daily Wage provider created: dailywage@localconnect.com';
  ELSE
    UPDATE auth.users SET encrypted_password = crypt('Provider@1234', gen_salt('bf', 10)), updated_at = now() WHERE id = existing_id;
    UPDATE public.service_providers SET registration_status = 'approved', is_active = true WHERE user_id = existing_id;
    RAISE NOTICE 'Daily Wage account already exists — password reset.';
  END IF;

  -- ── TRANSPORT: RIDE PROVIDER ───────────────────────────────
  SELECT id INTO existing_id FROM auth.users WHERE email = 'ride.provider@localconnect.com' LIMIT 1;
  IF existing_id IS NULL THEN
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
      ride_auth_id, '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'ride.provider@localconnect.com',
      crypt('Provider@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'Mohan Ride Driver', 'role', 'provider'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (ride_auth_id, 'ride.provider@localconnect.com', 'Mohan Ride Driver', '9000000018', 'provider', 'Pune', true)
    ON CONFLICT (email) DO NOTHING;
    INSERT INTO public.service_providers (
      id, user_id, business_name, owner_name, category, subcategory,
      description, phone, whatsapp, upi_id, address, city,
      rating, review_count, completed_orders, price_range,
      response_time, is_open, open_hours, today_offer,
      image_url, lat, lng, is_verified, is_active,
      member_since, onboarding_completed, earnings_total,
      accepted_orders, rejected_orders, registration_status
    ) VALUES (
      sp_ride_id, ride_auth_id,
      'Mohan Cab Service', 'Mohan Ride Driver', 'Transport', 'Ride',
      'Comfortable cab rides within Pune and outstation trips at affordable rates.',
      '9000000018', '9000000018', 'mohan.ride@upi',
      'Shivajinagar, Pune', 'Pune',
      4.6, 55, 80, '50 - 500',
      '< 10 min', true, '6:00 AM - 11:00 PM', 'First ride 20% off',
      'https://images.pexels.com/photos/1118448/pexels-photo-1118448.jpeg',
      18.5308, 73.8474, true, true,
      'Dec 2024', true, 40000.00, 80, 4, 'approved'
    ) ON CONFLICT (id) DO NOTHING;
    RAISE NOTICE 'Ride provider created: ride.provider@localconnect.com';
  ELSE
    UPDATE auth.users SET encrypted_password = crypt('Provider@1234', gen_salt('bf', 10)), updated_at = now() WHERE id = existing_id;
    UPDATE public.service_providers SET registration_status = 'approved', is_active = true WHERE user_id = existing_id;
    RAISE NOTICE 'Ride provider already exists — password reset.';
  END IF;

  -- ── TRANSPORT: GOODS PROVIDER ──────────────────────────────
  SELECT id INTO existing_id FROM auth.users WHERE email = 'goods.provider@localconnect.com' LIMIT 1;
  IF existing_id IS NULL THEN
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
      goods_auth_id, '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'goods.provider@localconnect.com',
      crypt('Provider@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'Santosh Goods Transport', 'role', 'provider'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (goods_auth_id, 'goods.provider@localconnect.com', 'Santosh Goods Transport', '9000000019', 'provider', 'Pune', true)
    ON CONFLICT (email) DO NOTHING;
    INSERT INTO public.service_providers (
      id, user_id, business_name, owner_name, category, subcategory,
      description, phone, whatsapp, upi_id, address, city,
      rating, review_count, completed_orders, price_range,
      response_time, is_open, open_hours, today_offer,
      image_url, lat, lng, is_verified, is_active,
      member_since, onboarding_completed, earnings_total,
      accepted_orders, rejected_orders, registration_status
    ) VALUES (
      sp_goods_id, goods_auth_id,
      'Santosh Goods Carrier', 'Santosh Goods Transport', 'Transport', 'Goods',
      'Mini truck and tempo for household shifting, office relocation, and goods delivery.',
      '9000000019', '9000000019', 'santosh.goods@upi',
      'Pimpri, Pune', 'Pune',
      4.4, 30, 42, '500 - 3000',
      '< 1 hour', true, '7:00 AM - 8:00 PM', 'Free packing assistance',
      'https://images.pexels.com/photos/1427541/pexels-photo-1427541.jpeg',
      18.6279, 73.7997, true, true,
      'Nov 2024', true, 21000.00, 42, 3, 'approved'
    ) ON CONFLICT (id) DO NOTHING;
    RAISE NOTICE 'Goods provider created: goods.provider@localconnect.com';
  ELSE
    UPDATE auth.users SET encrypted_password = crypt('Provider@1234', gen_salt('bf', 10)), updated_at = now() WHERE id = existing_id;
    UPDATE public.service_providers SET registration_status = 'approved', is_active = true WHERE user_id = existing_id;
    RAISE NOTICE 'Goods provider already exists — password reset.';
  END IF;

  -- ── EVENT MANAGEMENT: PHOTOGRAPHY ─────────────────────────
  SELECT id INTO existing_id FROM auth.users WHERE email = 'photography@localconnect.com' LIMIT 1;
  IF existing_id IS NULL THEN
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
      photo_auth_id, '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'photography@localconnect.com',
      crypt('Provider@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'Deepak Photographer', 'role', 'provider'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (photo_auth_id, 'photography@localconnect.com', 'Deepak Photographer', '9000000020', 'provider', 'Pune', true)
    ON CONFLICT (email) DO NOTHING;
    INSERT INTO public.service_providers (
      id, user_id, business_name, owner_name, category, subcategory,
      description, phone, whatsapp, upi_id, address, city,
      rating, review_count, completed_orders, price_range,
      response_time, is_open, open_hours, today_offer,
      image_url, lat, lng, is_verified, is_active,
      member_since, onboarding_completed, earnings_total,
      accepted_orders, rejected_orders, registration_status
    ) VALUES (
      sp_photo_id, photo_auth_id,
      'Deepak Photography Studio', 'Deepak Photographer', 'Event Management', 'Photography',
      'Professional wedding, birthday, and corporate event photography and videography.',
      '9000000020', '9000000020', 'deepak.photo@upi',
      'Koregaon Park, Pune', 'Pune',
      4.9, 65, 90, '5000 - 30000',
      '< 2 hours', true, '9:00 AM - 9:00 PM', 'Free pre-wedding shoot',
      'https://images.pexels.com/photos/1264210/pexels-photo-1264210.jpeg',
      18.5362, 73.8938, true, true,
      'Oct 2024', true, 90000.00, 90, 3, 'approved'
    ) ON CONFLICT (id) DO NOTHING;
    RAISE NOTICE 'Photography provider created: photography@localconnect.com';
  ELSE
    UPDATE auth.users SET encrypted_password = crypt('Provider@1234', gen_salt('bf', 10)), updated_at = now() WHERE id = existing_id;
    UPDATE public.service_providers SET registration_status = 'approved', is_active = true WHERE user_id = existing_id;
    RAISE NOTICE 'Photography provider already exists — password reset.';
  END IF;

  -- ── EVENT MANAGEMENT: DECORATION & CATERING ───────────────
  SELECT id INTO existing_id FROM auth.users WHERE email = 'decoration@localconnect.com' LIMIT 1;
  IF existing_id IS NULL THEN
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
      deco_auth_id, '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'decoration@localconnect.com',
      crypt('Provider@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'Priya Decoration', 'role', 'provider'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (deco_auth_id, 'decoration@localconnect.com', 'Priya Decoration', '9000000021', 'provider', 'Pune', true)
    ON CONFLICT (email) DO NOTHING;
    INSERT INTO public.service_providers (
      id, user_id, business_name, owner_name, category, subcategory,
      description, phone, whatsapp, upi_id, address, city,
      rating, review_count, completed_orders, price_range,
      response_time, is_open, open_hours, today_offer,
      image_url, lat, lng, is_verified, is_active,
      member_since, onboarding_completed, earnings_total,
      accepted_orders, rejected_orders, registration_status
    ) VALUES (
      sp_deco_id, deco_auth_id,
      'Priya Event Decorators', 'Priya Decoration', 'Event Management', 'Decoration',
      'Floral decoration, balloon setups, stage decoration, and catering for all events.',
      '9000000021', '9000000021', 'priya.deco@upi',
      'Viman Nagar, Pune', 'Pune',
      4.7, 48, 65, '3000 - 25000',
      '< 3 hours', true, '9:00 AM - 8:00 PM', 'Free cake with decoration package',
      'https://images.pexels.com/photos/1616113/pexels-photo-1616113.jpeg',
      18.5679, 73.9143, true, true,
      'Sep 2024', true, 65000.00, 65, 4, 'approved'
    ) ON CONFLICT (id) DO NOTHING;
    RAISE NOTICE 'Decoration provider created: decoration@localconnect.com';
  ELSE
    UPDATE auth.users SET encrypted_password = crypt('Provider@1234', gen_salt('bf', 10)), updated_at = now() WHERE id = existing_id;
    UPDATE public.service_providers SET registration_status = 'approved', is_active = true WHERE user_id = existing_id;
    RAISE NOTICE 'Decoration provider already exists — password reset.';
  END IF;

  -- ── EVENT MANAGEMENT: SOUND & DJ ──────────────────────────
  SELECT id INTO existing_id FROM auth.users WHERE email = 'sounddj@localconnect.com' LIMIT 1;
  IF existing_id IS NULL THEN
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
      sound_auth_id, '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'sounddj@localconnect.com',
      crypt('Provider@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'DJ Rahul Sound', 'role', 'provider'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (sound_auth_id, 'sounddj@localconnect.com', 'DJ Rahul Sound', '9000000022', 'provider', 'Pune', true)
    ON CONFLICT (email) DO NOTHING;
    INSERT INTO public.service_providers (
      id, user_id, business_name, owner_name, category, subcategory,
      description, phone, whatsapp, upi_id, address, city,
      rating, review_count, completed_orders, price_range,
      response_time, is_open, open_hours, today_offer,
      image_url, lat, lng, is_verified, is_active,
      member_since, onboarding_completed, earnings_total,
      accepted_orders, rejected_orders, registration_status
    ) VALUES (
      sp_sound_id, sound_auth_id,
      'DJ Rahul Sound System', 'DJ Rahul Sound', 'Event Management', 'Sound & DJ',
      'Professional DJ, sound system rental, and live music for weddings and parties.',
      '9000000022', '9000000022', 'djrahul.sound@upi',
      'Kharadi, Pune', 'Pune',
      4.5, 35, 50, '4000 - 20000',
      '< 2 hours', true, '10:00 AM - 11:00 PM', 'Free LED lights with DJ booking',
      'https://images.pexels.com/photos/1540406/pexels-photo-1540406.jpeg',
      18.5512, 73.9442, true, true,
      'Aug 2024', true, 50000.00, 50, 3, 'approved'
    ) ON CONFLICT (id) DO NOTHING;
    RAISE NOTICE 'Sound & DJ provider created: sounddj@localconnect.com';
  ELSE
    UPDATE auth.users SET encrypted_password = crypt('Provider@1234', gen_salt('bf', 10)), updated_at = now() WHERE id = existing_id;
    UPDATE public.service_providers SET registration_status = 'approved', is_active = true WHERE user_id = existing_id;
    RAISE NOTICE 'Sound & DJ provider already exists — password reset.';
  END IF;

  -- ── EVENT MANAGEMENT: MAKEUP & MEHENDI ────────────────────
  SELECT id INTO existing_id FROM auth.users WHERE email = 'makeup@localconnect.com' LIMIT 1;
  IF existing_id IS NULL THEN
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
      makeup_auth_id, '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated',
      'makeup@localconnect.com',
      crypt('Provider@1234', gen_salt('bf', 10)),
      now(), now(), now(),
      jsonb_build_object('full_name', 'Kavita Makeup Artist', 'role', 'provider'),
      jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
      false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
    );
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
    VALUES (makeup_auth_id, 'makeup@localconnect.com', 'Kavita Makeup Artist', '9000000023', 'provider', 'Pune', true)
    ON CONFLICT (email) DO NOTHING;
    INSERT INTO public.service_providers (
      id, user_id, business_name, owner_name, category, subcategory,
      description, phone, whatsapp, upi_id, address, city,
      rating, review_count, completed_orders, price_range,
      response_time, is_open, open_hours, today_offer,
      image_url, lat, lng, is_verified, is_active,
      member_since, onboarding_completed, earnings_total,
      accepted_orders, rejected_orders, registration_status
    ) VALUES (
      sp_makeup_id, makeup_auth_id,
      'Kavita Bridal Studio', 'Kavita Makeup Artist', 'Event Management', 'Makeup & Mehendi',
      'Bridal makeup, party makeup, mehendi designs, and pre-wedding beauty packages.',
      '9000000023', '9000000023', 'kavita.makeup@upi',
      'Camp, Pune', 'Pune',
      4.9, 72, 100, '2000 - 15000',
      '< 1 hour', true, '8:00 AM - 9:00 PM', 'Free mehendi with bridal package',
      'https://images.pexels.com/photos/3993449/pexels-photo-3993449.jpeg',
      18.5195, 73.8553, true, true,
      'Jul 2024', true, 100000.00, 100, 2, 'approved'
    ) ON CONFLICT (id) DO NOTHING;
    RAISE NOTICE 'Makeup & Mehendi provider created: makeup@localconnect.com';
  ELSE
    UPDATE auth.users SET encrypted_password = crypt('Provider@1234', gen_salt('bf', 10)), updated_at = now() WHERE id = existing_id;
    UPDATE public.service_providers SET registration_status = 'approved', is_active = true WHERE user_id = existing_id;
    RAISE NOTICE 'Makeup & Mehendi provider already exists — password reset.';
  END IF;

END $$;
