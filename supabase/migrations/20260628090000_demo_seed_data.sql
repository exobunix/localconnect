-- ============================================================
-- Demo Seed Data Migration
-- Only populates data when called explicitly via the
-- seed_demo_data() function. Safe to run in production
-- (function exists but does nothing unless invoked).
-- ============================================================

-- ── Helper: check if demo data already seeded ───────────────
CREATE OR REPLACE FUNCTION public.is_demo_data_seeded()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE email LIKE '%@demo.localconnect.com'
    LIMIT 1
  );
$$;

-- ── Main seeder function ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public.seed_demo_data()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $outer$
DECLARE
  -- customer UUIDs
  cust1_auth_id  UUID := gen_random_uuid();
  cust2_auth_id  UUID := gen_random_uuid();
  cust3_auth_id  UUID := gen_random_uuid();

  -- provider UUIDs
  prov1_auth_id  UUID := gen_random_uuid();
  prov2_auth_id  UUID := gen_random_uuid();
  prov3_auth_id  UUID := gen_random_uuid();

  -- service_providers row UUIDs
  sp1_id UUID := gen_random_uuid();
  sp2_id UUID := gen_random_uuid();
  sp3_id UUID := gen_random_uuid();

  -- order UUIDs
  ord1_id UUID := gen_random_uuid();
  ord2_id UUID := gen_random_uuid();
  ord3_id UUID := gen_random_uuid();
  ord4_id UUID := gen_random_uuid();
  ord5_id UUID := gen_random_uuid();
  ord6_id UUID := gen_random_uuid();
  ord7_id UUID := gen_random_uuid();
  ord8_id UUID := gen_random_uuid();

  -- subscription plan id
  plan_id UUID;

BEGIN
  -- Guard: skip if already seeded
  IF public.is_demo_data_seeded() THEN
    RETURN 'already_seeded';
  END IF;

  -- ── 1. Auth users ──────────────────────────────────────────
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
  ) VALUES
    -- Customers
    (cust1_auth_id, '00000000-0000-0000-0000-000000000000',
     'authenticated', 'authenticated',
     'priya.sharma@demo.localconnect.com',
     crypt('Demo@1234', gen_salt('bf', 10)), now(), now(), now(),
     jsonb_build_object('full_name', 'Priya Sharma', 'role', 'customer'),
     jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
     false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),

    (cust2_auth_id, '00000000-0000-0000-0000-000000000000',
     'authenticated', 'authenticated',
     'rahul.patil@demo.localconnect.com',
     crypt('Demo@1234', gen_salt('bf', 10)), now(), now(), now(),
     jsonb_build_object('full_name', 'Rahul Patil', 'role', 'customer'),
     jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
     false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),

    (cust3_auth_id, '00000000-0000-0000-0000-000000000000',
     'authenticated', 'authenticated',
     'sneha.desai@demo.localconnect.com',
     crypt('Demo@1234', gen_salt('bf', 10)), now(), now(), now(),
     jsonb_build_object('full_name', 'Sneha Desai', 'role', 'customer'),
     jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
     false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),

    -- Providers
    (prov1_auth_id, '00000000-0000-0000-0000-000000000000',
     'authenticated', 'authenticated',
     'ravi.plumber@demo.localconnect.com',
     crypt('Demo@1234', gen_salt('bf', 10)), now(), now(), now(),
     jsonb_build_object('full_name', 'Ravi Kumar', 'role', 'provider'),
     jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
     false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),

    (prov2_auth_id, '00000000-0000-0000-0000-000000000000',
     'authenticated', 'authenticated',
     'meena.salon@demo.localconnect.com',
     crypt('Demo@1234', gen_salt('bf', 10)), now(), now(), now(),
     jsonb_build_object('full_name', 'Meena Joshi', 'role', 'provider'),
     jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
     false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),

    (prov3_auth_id, '00000000-0000-0000-0000-000000000000',
     'authenticated', 'authenticated',
     'suresh.electric@demo.localconnect.com',
     crypt('Demo@1234', gen_salt('bf', 10)), now(), now(), now(),
     jsonb_build_object('full_name', 'Suresh Nair', 'role', 'provider'),
     jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
     false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null)
  ON CONFLICT (id) DO NOTHING;

  -- ── 2. user_profiles (trigger may have created them; upsert safely) ──
  INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active)
  VALUES
    (cust1_auth_id, 'priya.sharma@demo.localconnect.com',  'Priya Sharma',  '9876543210', 'customer', 'Pune', true),
    (cust2_auth_id, 'rahul.patil@demo.localconnect.com',   'Rahul Patil',   '9876543211', 'customer', 'Pune', true),
    (cust3_auth_id, 'sneha.desai@demo.localconnect.com',   'Sneha Desai',   '9876543212', 'customer', 'Pune', true),
    (prov1_auth_id, 'ravi.plumber@demo.localconnect.com',  'Ravi Kumar',    '9876543213', 'provider', 'Pune', true),
    (prov2_auth_id, 'meena.salon@demo.localconnect.com',   'Meena Joshi',   '9876543214', 'provider', 'Pune', true),
    (prov3_auth_id, 'suresh.electric@demo.localconnect.com','Suresh Nair',  '9876543215', 'provider', 'Pune', true)
  ON CONFLICT (email) DO NOTHING;

  -- ── 3. service_providers (approved) ───────────────────────
  INSERT INTO public.service_providers (
    id, user_id, business_name, owner_name, category, subcategory,
    description, phone, whatsapp, upi_id, address, city,
    rating, review_count, completed_orders, price_range,
    response_time, is_open, open_hours, today_offer,
    image_url, lat, lng, is_verified, is_active,
    member_since, onboarding_completed, earnings_total,
    accepted_orders, rejected_orders, registration_status
  ) VALUES
    (sp1_id, prov1_auth_id,
     'Ravi Plumbing Services', 'Ravi Kumar', 'Home Maintenance', 'Plumber',
     'Expert plumbing repairs, pipe fitting, and bathroom installations.',
     '9876543213', '9876543213', 'ravi.plumber@upi',
     'Kothrud, Pune', 'Pune',
     4.7, 38, 52, '₹200 - ₹800',
     '< 30 min', true, '8:00 AM - 7:00 PM', '10% off today',
     'https://images.pexels.com/photos/1216589/pexels-photo-1216589.jpeg',
     18.5074, 73.8077, true, true,
     'Jan 2024', true, 24800.00, 52, 3, 'approved'),

    (sp2_id, prov2_auth_id,
     'Meena Beauty Salon', 'Meena Joshi', 'Shop', 'Beauty Salon',
     'Full-service beauty salon offering haircuts, facials, and bridal packages.',
     '9876543214', '9876543214', 'meena.salon@upi',
     'Baner, Pune', 'Pune',
     4.9, 61, 89, '₹300 - ₹2000',
     '< 15 min', true, '9:00 AM - 8:00 PM', 'Free hair wash with haircut',
     'https://images.pexels.com/photos/3993449/pexels-photo-3993449.jpeg',
     18.5590, 73.7868, true, true,
     'Nov 2023', true, 67200.00, 89, 5, 'approved'),

    (sp3_id, prov3_auth_id,
     'Suresh Electricals', 'Suresh Nair', 'Home Maintenance', 'Electrician',
     'Licensed electrician for wiring, repairs, and appliance installation.',
     '9876543215', '9876543215', 'suresh.electric@upi',
     'Wakad, Pune', 'Pune',
     4.5, 27, 41, '₹300 - ₹1500',
     '< 45 min', true, '8:30 AM - 6:30 PM', 'Free inspection today',
     'https://images.pexels.com/photos/257736/pexels-photo-257736.jpeg',
     18.5975, 73.7898, true, true,
     'Mar 2024', true, 18400.00, 41, 4, 'approved')
  ON CONFLICT (id) DO NOTHING;

  -- ── 4. Orders ──────────────────────────────────────────────
  INSERT INTO public.orders (
    id, order_number, customer_id, provider_id, provider_name,
    service, category, scheduled_date, scheduled_time,
    amount, status, rating, notes, reviewed
  ) VALUES
    -- Completed orders (reviewable)
    (ord1_id, 'LC-DEMO-001', cust1_auth_id, sp1_id, 'Ravi Plumbing Services',
     'Pipe Leak Repair', 'Home Maintenance', '2026-06-10', '10:00 AM',
     '₹450', 'completed', 5, 'Fixed kitchen sink leak quickly.', true),

    (ord2_id, 'LC-DEMO-002', cust2_auth_id, sp2_id, 'Meena Beauty Salon',
     'Haircut & Styling', 'Shop', '2026-06-12', '11:30 AM',
     '₹600', 'completed', 5, 'Excellent service, very happy.', true),

    (ord3_id, 'LC-DEMO-003', cust3_auth_id, sp3_id, 'Suresh Electricals',
     'Fan Installation', 'Home Maintenance', '2026-06-15', '2:00 PM',
     '₹350', 'completed', 4, 'Professional and on time.', true),

    (ord4_id, 'LC-DEMO-004', cust1_auth_id, sp2_id, 'Meena Beauty Salon',
     'Facial Treatment', 'Shop', '2026-06-18', '3:00 PM',
     '₹1200', 'completed', 5, 'Amazing facial, skin feels great.', true),

    -- Active / upcoming orders
    (ord5_id, 'LC-DEMO-005', cust2_auth_id, sp1_id, 'Ravi Plumbing Services',
     'Bathroom Fitting', 'Home Maintenance', '2026-06-29', '9:00 AM',
     '₹800', 'active', null, 'New bathroom tap installation.', false),

    (ord6_id, 'LC-DEMO-006', cust3_auth_id, sp2_id, 'Meena Beauty Salon',
     'Bridal Makeup', 'Shop', '2026-07-02', '7:00 AM',
     '₹3500', 'upcoming', null, 'Wedding on 2nd July.', false),

    -- Pending orders
    (ord7_id, 'LC-DEMO-007', cust1_auth_id, sp3_id, 'Suresh Electricals',
     'Wiring Repair', 'Home Maintenance', '2026-06-30', '11:00 AM',
     '₹700', 'pending', null, 'Short circuit in bedroom.', false),

    (ord8_id, 'LC-DEMO-008', cust2_auth_id, sp3_id, 'Suresh Electricals',
     'AC Installation', 'Home Maintenance', '2026-07-05', '10:00 AM',
     '₹1500', 'pending', null, 'New 1.5 ton AC unit.', false)
  ON CONFLICT (order_number) DO NOTHING;

  -- ── 5. Reviews ─────────────────────────────────────────────
  INSERT INTO public.reviews (
    id, order_id, customer_id, provider_id,
    rating, review_text, provider_name, service
  ) VALUES
    (gen_random_uuid(), ord1_id, cust1_auth_id, sp1_id,
     5, 'Ravi fixed the leak in under 30 minutes. Very professional and affordable. Highly recommended!',
     'Ravi Plumbing Services', 'Pipe Leak Repair'),

    (gen_random_uuid(), ord2_id, cust2_auth_id, sp2_id,
     5, 'Meena is incredibly talented. Best haircut I have had in years. The salon is clean and welcoming.',
     'Meena Beauty Salon', 'Haircut & Styling'),

    (gen_random_uuid(), ord3_id, cust3_auth_id, sp3_id,
     4, 'Suresh installed the fan perfectly. Arrived on time and cleaned up after the work. Good service.',
     'Suresh Electricals', 'Fan Installation'),

    (gen_random_uuid(), ord4_id, cust1_auth_id, sp2_id,
     5, 'The facial was absolutely wonderful. My skin has never looked better. Will definitely return!',
     'Meena Beauty Salon', 'Facial Treatment')
  ON CONFLICT (order_id) DO NOTHING;

  -- ── 6. Earnings records (transactions) ────────────────────
  INSERT INTO public.earnings_records (
    id, provider_id, order_id, amount, type, description, status
  ) VALUES
    (gen_random_uuid(), sp1_id, ord1_id, 405.00, 'order',
     'Pipe Leak Repair - LC-DEMO-001', 'credited'),

    (gen_random_uuid(), sp2_id, ord2_id, 540.00, 'order',
     'Haircut & Styling - LC-DEMO-002', 'credited'),

    (gen_random_uuid(), sp3_id, ord3_id, 315.00, 'order',
     'Fan Installation - LC-DEMO-003', 'credited'),

    (gen_random_uuid(), sp2_id, ord4_id, 1080.00, 'order',
     'Facial Treatment - LC-DEMO-004', 'credited'),

    -- Bonus records
    (gen_random_uuid(), sp2_id, null, 200.00, 'bonus',
     'Top Provider Bonus - June 2026', 'credited'),

    (gen_random_uuid(), sp1_id, null, 100.00, 'bonus',
     'New Provider Welcome Bonus', 'credited')
  ON CONFLICT (id) DO NOTHING;

  -- ── 7. Subscriptions ───────────────────────────────────────
  SELECT id INTO plan_id FROM public.subscription_plans
  WHERE is_active = true LIMIT 1;

  IF plan_id IS NOT NULL THEN
    INSERT INTO public.provider_subscriptions (
      id, provider_id, plan_id, status, started_at, expires_at, payment_ref
    ) VALUES
      (gen_random_uuid(), sp1_id, plan_id, 'active',
       now() - interval '15 days', now() + interval '15 days', 'DEMO-PAY-001'),

      (gen_random_uuid(), sp2_id, plan_id, 'active',
       now() - interval '5 days', now() + interval '25 days', 'DEMO-PAY-002'),

      (gen_random_uuid(), sp3_id, plan_id, 'active',
       now() - interval '20 days', now() + interval '10 days', 'DEMO-PAY-003')
    ON CONFLICT (id) DO NOTHING;
  END IF;

  -- ── 8. Order tracking for active order ────────────────────
  INSERT INTO public.order_tracking (
    id, order_id, current_step,
    provider_lat, provider_lng, eta_minutes,
    confirmed_at, accepted_at
  ) VALUES
    (gen_random_uuid(), ord5_id, 'provider_accepted',
     18.5074, 73.8077, 20,
     now() - interval '2 hours', now() - interval '1 hour 50 minutes')
  ON CONFLICT (id) DO NOTHING;

  -- ── 9. Saved addresses for customers ──────────────────────
  INSERT INTO public.saved_addresses (
    id, user_id, label, address_line1, address_line2,
    city, state, pincode, is_default
  ) VALUES
    (gen_random_uuid(), cust1_auth_id, 'Home',
     'Flat 4B, Sunrise Apartments, Kothrud', 'Near Karve Road',
     'Pune', 'Maharashtra', '411038', true),

    (gen_random_uuid(), cust2_auth_id, 'Home',
     '12, Shivaji Nagar, Baner Road', null,
     'Pune', 'Maharashtra', '411045', true),

    (gen_random_uuid(), cust3_auth_id, 'Home',
     '7, Green Valley Society, Wakad', 'Opposite D-Mart',
     'Pune', 'Maharashtra', '411057', true)
  ON CONFLICT (id) DO NOTHING;

  -- ── 10. Notifications for demo users ──────────────────────
  INSERT INTO public.notifications (
    id, user_id, title, body, type, is_read
  ) VALUES
    (gen_random_uuid(), cust1_auth_id,
     'Order Confirmed!',
     'Your booking for Pipe Leak Repair has been confirmed.',
     'order', true),

    (gen_random_uuid(), cust2_auth_id,
     'Provider On the Way',
     'Ravi Kumar is heading to your location. ETA: 20 minutes.',
     'order', false),

    (gen_random_uuid(), prov1_auth_id,
     'New Order Request',
     'You have a new booking request for Bathroom Fitting.',
     'order', false),

    (gen_random_uuid(), prov2_auth_id,
     'Payment Received',
     'You received ₹540 for Haircut & Styling service.',
     'payment', true)
  ON CONFLICT (id) DO NOTHING;

  RETURN 'seeded';

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Demo seed failed: %', SQLERRM;
    RETURN 'error: ' || SQLERRM;
END;
$outer$;

-- ── Cleanup function (removes all demo data) ────────────────
CREATE OR REPLACE FUNCTION public.clear_demo_data()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $outer$
DECLARE
  demo_user_ids UUID[];
  demo_sp_ids   UUID[];
BEGIN
  SELECT ARRAY_AGG(id) INTO demo_user_ids
  FROM public.user_profiles
  WHERE email LIKE '%@demo.localconnect.com';

  IF demo_user_ids IS NULL OR array_length(demo_user_ids, 1) = 0 THEN
    RETURN 'no_demo_data';
  END IF;

  SELECT ARRAY_AGG(id) INTO demo_sp_ids
  FROM public.service_providers
  WHERE user_id = ANY(demo_user_ids);

  -- Delete in dependency order
  DELETE FROM public.notifications     WHERE user_id = ANY(demo_user_ids);
  DELETE FROM public.order_tracking    WHERE order_id IN (
    SELECT id FROM public.orders WHERE customer_id = ANY(demo_user_ids)
      OR provider_id = ANY(demo_sp_ids));
  DELETE FROM public.earnings_records  WHERE provider_id = ANY(demo_sp_ids);
  DELETE FROM public.provider_subscriptions WHERE provider_id = ANY(demo_sp_ids);
  DELETE FROM public.reviews           WHERE customer_id = ANY(demo_user_ids);
  DELETE FROM public.orders            WHERE customer_id = ANY(demo_user_ids)
                                          OR provider_id = ANY(demo_sp_ids);
  DELETE FROM public.saved_addresses   WHERE user_id = ANY(demo_user_ids);
  DELETE FROM public.service_providers WHERE id = ANY(demo_sp_ids);
  DELETE FROM public.user_profiles     WHERE id = ANY(demo_user_ids);
  DELETE FROM auth.users               WHERE id = ANY(demo_user_ids);

  RETURN 'cleared';

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Demo clear failed: %', SQLERRM;
    RETURN 'error: ' || SQLERRM;
END;
$outer$;
