-- ============================================================================
-- Complete Service Providers Seed & RLS Permission Fix Migration
-- Run this entire script in Supabase SQL Editor
-- Sets up permissions, schemas, and creates ready-to-login provider accounts.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. Ensure columns and permissions on user_profiles
ALTER TABLE public.user_profiles 
  ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS city TEXT DEFAULT 'Pune',
  ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'customer';

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "allow_all_user_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "public_read_user_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "users_manage_own" ON public.user_profiles;

CREATE POLICY "allow_all_user_profiles"
  ON public.user_profiles FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

GRANT ALL ON public.user_profiles TO anon, authenticated, service_role;

-- 2. Ensure permissions on service_providers table (Fixes 42501 Unauthorized)
ALTER TABLE public.service_providers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "allow_all_service_providers" ON public.service_providers;
DROP POLICY IF EXISTS "public_read_service_providers" ON public.service_providers;
DROP POLICY IF EXISTS "providers_manage_own" ON public.service_providers;
DROP POLICY IF EXISTS "admin_manage_service_providers" ON public.service_providers;
DROP POLICY IF EXISTS "providers_update_own_provider_record" ON public.service_providers;

CREATE POLICY "allow_all_service_providers"
  ON public.service_providers FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

GRANT ALL ON public.service_providers TO anon, authenticated, service_role;

-- 3. Create all Provider Accounts in auth.users, user_profiles, and service_providers
DO $$
DECLARE
  pwd_hash TEXT := crypt('Provider@1234', gen_salt('bf', 10));
  demo_hash TEXT := crypt('localconnect123', gen_salt('bf', 10));
  r RECORD;
  new_uid UUID;
  existing_uid UUID;
  sp_id UUID;
BEGIN

  CREATE TEMP TABLE temp_providers (
    email TEXT,
    password_hash TEXT,
    full_name TEXT,
    business_name TEXT,
    category TEXT,
    subcategory TEXT,
    phone TEXT,
    city TEXT,
    price_range TEXT,
    rating NUMERIC
  ) ON COMMIT DROP;

  INSERT INTO temp_providers VALUES
    -- Demo accounts matching localconnect123 password
    ('priya@demo.localconnect.com', demo_hash, 'Priya Sharma', 'Alibag Events & Decor', 'Events', 'Decoration', '9876500001', 'Pune', '₹3000 - ₹30000', 4.9),
    ('ravi@demo.localconnect.com', demo_hash, 'Ravi Kumar', 'Ravi Plumbing Services', 'Home Maintenance', 'Plumber', '9876500002', 'Pune', '₹200 - ₹800', 4.8),
    ('suresh@demo.localconnect.com', demo_hash, 'Suresh Transport', 'Roha Transport Co.', 'Transport', 'Mini / Sedan Cab', '9876500003', 'Pune', '₹200 - ₹2000', 4.7),
    ('mohan@demo.localconnect.com', demo_hash, 'Mohan Electricals', 'City Electricals Shop', 'Shop', 'Electrical & Hardware', '9876500004', 'Pune', '₹100 - ₹8000', 4.6),
    ('anita@demo.localconnect.com', demo_hash, 'Anita Rooms', 'Nagothane Rent Rooms', 'Rent', 'Room', '9876500005', 'Pune', '₹3000 - ₹12000', 4.8),

    -- Home Maintenance (13)
    ('plumber@localconnect.com', pwd_hash, 'Ramesh Plumber', 'Ramesh Plumbing Works', 'Home Maintenance', 'Plumber', '9000000011', 'Pune', '₹200 - ₹800', 4.8),
    ('electrician@localconnect.com', pwd_hash, 'Vijay Electrician', 'Vijay Electrical Services', 'Home Maintenance', 'Electrician', '9000000012', 'Pune', '₹300 - ₹1500', 4.9),
    ('carpenter@localconnect.com', pwd_hash, 'Sunil Carpenter', 'Sunil Carpentry Studio', 'Home Maintenance', 'Carpenter', '9000000013', 'Pune', '₹500 - ₹3000', 4.7),
    ('painter@localconnect.com', pwd_hash, 'Anil Painter', 'Anil Painting & Decor', 'Home Maintenance', 'Painter', '9000000014', 'Pune', '₹1000 - ₹8000', 4.6),
    ('mason@localconnect.com', pwd_hash, 'Ganesh Mason', 'Ganesh Civil & Masonry', 'Home Maintenance', 'Mason', '9000000015', 'Pune', '₹800 - ₹5000', 4.5),
    ('cleaning@localconnect.com', pwd_hash, 'Sunita Cleaning', 'Sunita Deep Cleaning', 'Home Maintenance', 'Cleaning', '9000000016', 'Pune', '₹400 - ₹2500', 4.9),
    ('dailywage@localconnect.com', pwd_hash, 'Raju Helper', 'Raju Daily Wage Helpers', 'Home Maintenance', 'Daily Wage', '9000000017', 'Pune', '₹350 - ₹700', 4.6),
    ('acrepair@localconnect.com', pwd_hash, 'Imran AC Expert', 'Cool Care AC Repair', 'Home Maintenance', 'AC Repair & Service', '9000000024', 'Pune', '₹499 - ₹2499', 4.8),
    ('appliance@localconnect.com', pwd_hash, 'Mahesh Repair', 'Mahesh Appliance Care', 'Home Maintenance', 'Appliance Repair', '9000000025', 'Pune', '₹299 - ₹1800', 4.7),
    ('pestcontrol@localconnect.com', pwd_hash, 'Suraksha Pest', 'Suraksha Pest Control', 'Home Maintenance', 'Pest Control', '9000000026', 'Pune', '₹699 - ₹3500', 4.8),
    ('roservice@localconnect.com', pwd_hash, 'PureWater RO', 'PureWater RO & Filter Care', 'Home Maintenance', 'RO Water Purifier', '9000000027', 'Pune', '₹299 - ₹1200', 4.9),
    ('locksmith@localconnect.com', pwd_hash, 'Chavi Locksmith', 'Master Locksmith & Keys', 'Home Maintenance', 'Locksmith', '9000000028', 'Pune', '₹150 - ₹800', 4.6),
    ('cctv@localconnect.com', pwd_hash, 'Vision CCTV', 'Vision CCTV & Security Setup', 'Home Maintenance', 'CCTV & Security', '9000000029', 'Pune', '₹999 - ₹8999', 4.9),

    -- Transport (12)
    ('biketaxi@localconnect.com', pwd_hash, 'Akash Bike Rider', 'Speedy Bike Taxi', 'Transport', 'Bike Taxi', '9000000030', 'Pune', '₹30 - ₹150', 4.8),
    ('auto@localconnect.com', pwd_hash, 'Santosh Auto', 'City Auto Rickshaw', 'Transport', 'Auto Rickshaw', '9000000031', 'Pune', '₹50 - ₹300', 4.7),
    ('cab@localconnect.com', pwd_hash, 'Mohan Cab Driver', 'Mohan Cab Services', 'Transport', 'Mini / Sedan Cab', '9000000018', 'Pune', '₹200 - ₹2000', 4.8),
    ('suv@localconnect.com', pwd_hash, 'Rajesh SUV Tours', 'Rajesh Premium SUV Rentals', 'Transport', 'SUV / Ertiga', '9000000032', 'Pune', '₹500 - ₹5000', 4.9),
    ('minitruck@localconnect.com', pwd_hash, 'Santosh Tempo', 'Santosh Goods Tempo', 'Transport', 'Mini Truck / Tata Ace', '9000000019', 'Pune', '₹400 - ₹2500', 4.6),
    ('pickuptempo@localconnect.com', pwd_hash, 'Balaji Pickup', 'Balaji Pickup Delivery', 'Transport', 'Pickup 8ft / Bolero', '9000000033', 'Pune', '₹600 - ₹3500', 4.7),
    ('largetruck@localconnect.com', pwd_hash, 'Maharashtra Transport', 'Maharashtra Heavy Trucking', 'Transport', 'Large Truck (14ft+)', '9000000034', 'Pune', '₹1500 - ₹12000', 4.5),
    ('packers@localconnect.com', pwd_hash, 'SafeMove Packers', 'SafeMove Packers & Movers', 'Transport', 'Packers & Movers', '9000000035', 'Pune', '₹2500 - ₹25000', 4.9),
    ('heavyvehicle@localconnect.com', pwd_hash, 'Kisan JCB & Crane', 'Kisan Heavy Equipment', 'Transport', 'JCB / Crane / Dumper', '9000000036', 'Pune', '₹1500 - ₹8000/hr', 4.8),
    ('ambulance@localconnect.com', pwd_hash, 'LifeLine 24x7', 'LifeLine Emergency Ambulance', 'Transport', 'Emergency Ambulance', '9000000037', 'Pune', '₹500 - ₹3000', 4.9),
    ('tractor@localconnect.com', pwd_hash, 'Gramin Agro', 'Gramin Tractor & Trolley', 'Transport', 'Tractor & Trolley', '9000000038', 'Pune', '₹800 - ₹3000', 4.6),
    ('luxurycar@localconnect.com', pwd_hash, 'Royal Wedding Cars', 'Royal Wedding Luxury Cars', 'Transport', 'Luxury / Wedding Car', '9000000039', 'Pune', '₹5000 - ₹35000', 4.9),

    -- Events (15)
    ('photography@localconnect.com', pwd_hash, 'Deepak Studio', 'Deepak Photography Studio', 'Events', 'Photography', '9000000020', 'Pune', '₹5000 - ₹40000', 4.9),
    ('decoration@localconnect.com', pwd_hash, 'Priya Decor', 'Priya Events & Decorators', 'Events', 'Decoration', '9000000021', 'Pune', '₹3000 - ₹30000', 4.8),
    ('sounddj@localconnect.com', pwd_hash, 'DJ Rahul', 'DJ Rahul Sound & Bass', 'Events', 'Sound & DJ', '9000000022', 'Pune', '₹4000 - ₹25000', 4.7),
    ('makeup@localconnect.com', pwd_hash, 'Kavita Bridal', 'Kavita Bridal & Makeup Studio', 'Events', 'Makeup & Mehendi', '9000000023', 'Pune', '₹1500 - ₹18000', 4.9),
    ('catering@localconnect.com', pwd_hash, 'Swad Caterers', 'Swad Royal Caterers', 'Events', 'Catering & Food', '9000000040', 'Pune', '₹250 - ₹1200/plate', 4.8),
    ('mandap@localconnect.com', pwd_hash, 'Shree Mandap', 'Shree Mandap & Shamiyana', 'Events', 'Mandap & Shamiyana', '9000000041', 'Pune', '₹5000 - ₹50000', 4.6),
    ('stage@localconnect.com', pwd_hash, 'Glow Stage Lights', 'Glow Stage & Truss Setup', 'Events', 'Stage & Lighting', '9000000042', 'Pune', '₹3000 - ₹20000', 4.7),
    ('anchor@localconnect.com', pwd_hash, 'Neha Emcee', 'Anchor Neha Event Host', 'Events', 'Anchor / Emcee', '9000000043', 'Pune', '₹3000 - ₹15000', 4.9),
    ('orchestra@localconnect.com', pwd_hash, 'Sur Sangeet', 'Sur Sangeet Live Band', 'Events', 'Live Band / Orchestra', '9000000044', 'Pune', '₹8000 - ₹45000', 4.8),
    ('magician@localconnect.com', pwd_hash, 'Jadugar Anand', 'Jadugar Anand Kids Magic Show', 'Events', 'Magician / Entertainer', '9000000045', 'Pune', '₹2500 - ₹8000', 4.8),
    ('cake@localconnect.com', pwd_hash, 'SweetDelight Cakes', 'SweetDelight Custom Cakes', 'Events', 'Cake & Bakery', '9000000046', 'Pune', '₹450 - ₹3500', 4.9),
    ('invitation@localconnect.com', pwd_hash, 'ArtPrint Cards', 'ArtPrint Wedding & Card Print', 'Events', 'Invitation Printing', '9000000047', 'Pune', '₹15 - ₹200/card', 4.7),
    ('valet@localconnect.com', pwd_hash, 'Apex Valet', 'Apex Valet Parking Services', 'Events', 'Valet Parking', '9000000048', 'Pune', '₹2000 - ₹15000', 4.8),
    ('generator@localconnect.com', pwd_hash, 'PowerGen Rentals', 'PowerGen Silent Generator', 'Events', 'Generator Rental', '9000000049', 'Pune', '₹1500 - ₹10000', 4.7),
    ('chairtable@localconnect.com', pwd_hash, 'EventEquip Rentals', 'EventEquip Chairs & Tables', 'Events', 'Chair & Table Rental', '9000000050', 'Pune', '₹10 - ₹200/item', 4.6),

    -- Shop (6)
    ('grocery@localconnect.com', pwd_hash, 'Laxmi Kirana', 'Laxmi Super Kirana Store', 'Shop', 'grocery shop', '9000000051', 'Pune', '₹50 - ₹5000', 4.8),
    ('hardware@localconnect.com', pwd_hash, 'Bharat Hardware', 'Bharat Electricals & Hardware', 'Shop', 'Electrical & Hardware', '9000000052', 'Pune', '₹100 - ₹8000', 4.7),
    ('meatfish@localconnect.com', pwd_hash, 'FreshCatch Meat', 'FreshCatch Chicken, Mutton & Fish', 'Shop', 'Mutton, Chicken & Fish', '9000000053', 'Pune', '₹150 - ₹1200', 4.8),
    ('vegetables@localconnect.com', pwd_hash, 'Kisan Fresh Farm', 'Kisan Fresh Vegetables & Fruits', 'Shop', 'Vegetables & Fruits', '9000000054', 'Pune', '₹40 - ₹600', 4.9),
    ('seasonal@localconnect.com', pwd_hash, 'Festival World', 'Festival & Seasonal Items Shop', 'Shop', 'Seasonal Items', '9000000055', 'Pune', '₹100 - ₹3000', 4.6),
    ('generalshop@localconnect.com', pwd_hash, 'Metro General', 'Metro General & Stationery Store', 'Shop', 'Others', '9000000056', 'Pune', '₹20 - ₹2000', 4.7),

    -- Delivery (10)
    ('fooddelivery@localconnect.com', pwd_hash, 'HotBite Express', 'HotBite Food Express', 'Delivery', 'Food Delivery', '9000000057', 'Pune', '₹30 - ₹120', 4.8),
    ('grocerydelivery@localconnect.com', pwd_hash, 'QuickKart Delivery', 'QuickKart Instant Grocery Drop', 'Delivery', 'Grocery Delivery', '9000000058', 'Pune', '₹25 - ₹100', 4.8),
    ('medicinedelivery@localconnect.com', pwd_hash, 'MedExpress 24x7', 'MedExpress Pharmacy Delivery', 'Delivery', 'Medicine Delivery', '9000000059', 'Pune', '₹20 - ₹80', 4.9),
    ('parcel@localconnect.com', pwd_hash, 'CityCourier Runner', 'CityCourier Parcel & Documents', 'Delivery', 'Parcel & Document', '9000000060', 'Pune', '₹40 - ₹250', 4.7),
    ('shoppurchase@localconnect.com', pwd_hash, 'AnyStore Buyer', 'AnyStore Personal Shopper & Delivery', 'Delivery', 'Shop Purchase & Delivery', '9000000061', 'Pune', '₹50 - ₹300', 4.8),
    ('pickupdrop@localconnect.com', pwd_hash, 'SwiftDrop Runner', 'SwiftDrop Intra-City Pick & Drop', 'Delivery', 'Pickup & Drop', '9000000062', 'Pune', '₹35 - ₹200', 4.8),
    ('heavydelivery@localconnect.com', pwd_hash, 'HeavyHaul Cargo', 'HeavyHaul Furniture & Appliances', 'Delivery', 'Heavy Item Delivery', '9000000063', 'Pune', '₹200 - ₹1500', 4.7),
    ('expressdelivery@localconnect.com', pwd_hash, 'FlashRunner 15m', 'FlashRunner 15-Minute Express', 'Delivery', 'Express Delivery', '9000000064', 'Pune', '₹50 - ₹180', 4.9),
    ('scheduleddelivery@localconnect.com', pwd_hash, 'TimeSlot Logistics', 'TimeSlot Scheduled Drop', 'Delivery', 'Scheduled Delivery', '9000000065', 'Pune', '₹40 - ₹200', 4.7),
    ('intercitydelivery@localconnect.com', pwd_hash, 'StateConnect Logistics', 'StateConnect Pune-Mumbai Intercity', 'Delivery', 'Intercity Delivery', '9000000066', 'Pune', '₹150 - ₹1800', 4.8),

    -- Rent (5)
    ('rentroom@localconnect.com', pwd_hash, 'GreenHomes Rooms', 'GreenHomes Budget Rental Rooms', 'Rent', 'Room', '9000000067', 'Pune', '₹3000 - ₹12000/mo', 4.7),
    ('pg@localconnect.com', pwd_hash, 'ComfortStay PG', 'ComfortStay Boys & Girls PG', 'Rent', 'PG', '9000000068', 'Pune', '₹4500 - ₹9500/mo', 4.8),
    ('hostel@localconnect.com', pwd_hash, 'YouthHub Hostel', 'YouthHub Student & Executive Hostel', 'Rent', 'Hostel', '9000000069', 'Pune', '₹3500 - ₹7500/mo', 4.6),
    ('villa@localconnect.com', pwd_hash, 'HillView Retreat', 'HillView Luxury Villa & Holiday Home', 'Rent', 'Villa / Holiday Home', '9000000070', 'Pune', '₹4000 - ₹25000/day', 4.9),
    ('toolsrent@localconnect.com', pwd_hash, 'ToolMaster Rental', 'ToolMaster Power Tools & Equipment', 'Rent', 'Tools & Equipment', '9000000071', 'Pune', '₹150 - ₹2000/day', 4.8);

  -- Loop through all providers and upsert into auth.users, user_profiles, and service_providers
  FOR r IN SELECT * FROM temp_providers LOOP
    SELECT id INTO existing_uid FROM auth.users WHERE email = r.email LIMIT 1;
    
    IF existing_uid IS NULL THEN
      new_uid := gen_random_uuid();
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
        new_uid, '00000000-0000-0000-0000-000000000000',
        'authenticated', 'authenticated',
        r.email, r.password_hash,
        now(), now(), now(),
        jsonb_build_object('full_name', r.full_name, 'role', 'provider'),
        jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
        false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
      );
    ELSE
      new_uid := existing_uid;
      UPDATE auth.users 
      SET encrypted_password = r.password_hash, updated_at = now() 
      WHERE id = new_uid;
    END IF;

    -- Upsert user_profiles
    INSERT INTO public.user_profiles (id, email, full_name, phone, role, city, is_active, is_verified)
    VALUES (new_uid, r.email, r.full_name, r.phone, 'provider', r.city, true, true)
    ON CONFLICT (id) DO UPDATE 
    SET role = 'provider', is_active = true, is_verified = true, full_name = EXCLUDED.full_name;

    -- Upsert service_providers
    SELECT id INTO sp_id FROM public.service_providers WHERE user_id = new_uid LIMIT 1;
    IF sp_id IS NULL THEN
      INSERT INTO public.service_providers (
        id, user_id, business_name, owner_name, category, subcategory,
        description, phone, whatsapp, upi_id, address, city,
        rating, review_count, completed_orders, price_range,
        response_time, is_open, open_hours, today_offer,
        is_verified, is_active, onboarding_completed, earnings_total,
        accepted_orders, rejected_orders, registration_status
      ) VALUES (
        gen_random_uuid(), new_uid, r.business_name, r.full_name, r.category, r.subcategory,
        r.business_name || ' provides reliable ' || r.subcategory || ' services across ' || r.city || '.',
        r.phone, r.phone, replace(lower(r.email), '@localconnect.com', '@upi'),
        r.city || ', Maharashtra', r.city,
        r.rating, floor(random() * 40 + 10)::int, floor(random() * 80 + 20)::int, r.price_range,
        '< 30 min', true, '8:00 AM - 8:00 PM', '10% off on first booking',
        true, true, true, (floor(random() * 40000 + 15000))::numeric,
        floor(random() * 50 + 20)::int, floor(random() * 3)::int, 'approved'
      );
    ELSE
      UPDATE public.service_providers
      SET business_name = r.business_name,
          category = r.category,
          subcategory = r.subcategory,
          is_verified = true,
          is_active = true,
          registration_status = 'approved',
          onboarding_completed = true
      WHERE id = sp_id;
    END IF;

  END LOOP;
  
  -- Reload schema cache
  NOTIFY pgrst, 'reload schema';
END $$;
