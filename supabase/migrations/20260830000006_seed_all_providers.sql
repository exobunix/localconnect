-- ============================================================================
-- Complete 50+ Service Providers Seed & Auth Setup Migration
-- Sets up ready-to-login provider accounts for every subcategory in LocalConnect
-- Password for all providers: Provider@1234
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
  pwd_hash TEXT := crypt('Provider@1234', gen_salt('bf', 10));
  
  -- Helper procedure logic in loop
  r RECORD;
  new_uid UUID;
  existing_uid UUID;
  sp_id UUID;
BEGIN

  -- 1. Temporary table of all subcategory providers
  CREATE TEMP TABLE temp_providers (
    email TEXT,
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
    -- Home Maintenance (13)
    ('plumber@localconnect.com', 'Ramesh Plumber', 'Ramesh Plumbing Works', 'Home Maintenance', 'Plumber', '9000000011', 'Pune', '₹200 - ₹800', 4.8),
    ('electrician@localconnect.com', 'Vijay Electrician', 'Vijay Electrical Services', 'Home Maintenance', 'Electrician', '9000000012', 'Pune', '₹300 - ₹1500', 4.9),
    ('carpenter@localconnect.com', 'Sunil Carpenter', 'Sunil Carpentry Studio', 'Home Maintenance', 'Carpenter', '9000000013', 'Pune', '₹500 - ₹3000', 4.7),
    ('painter@localconnect.com', 'Anil Painter', 'Anil Painting & Decor', 'Home Maintenance', 'Painter', '9000000014', 'Pune', '₹1000 - ₹8000', 4.6),
    ('mason@localconnect.com', 'Ganesh Mason', 'Ganesh Civil & Masonry', 'Home Maintenance', 'Mason', '9000000015', 'Pune', '₹800 - ₹5000', 4.5),
    ('cleaning@localconnect.com', 'Sunita Cleaning', 'Sunita Deep Cleaning', 'Home Maintenance', 'Cleaning', '9000000016', 'Pune', '₹400 - ₹2500', 4.9),
    ('dailywage@localconnect.com', 'Raju Helper', 'Raju Daily Wage Helpers', 'Home Maintenance', 'Daily Wage', '9000000017', 'Pune', '₹350 - ₹700', 4.6),
    ('acrepair@localconnect.com', 'Imran AC Expert', 'Cool Care AC Repair', 'Home Maintenance', 'AC Repair & Service', '9000000024', 'Pune', '₹499 - ₹2499', 4.8),
    ('appliance@localconnect.com', 'Mahesh Repair', 'Mahesh Appliance Care', 'Home Maintenance', 'Appliance Repair', '9000000025', 'Pune', '₹299 - ₹1800', 4.7),
    ('pestcontrol@localconnect.com', 'Suraksha Pest', 'Suraksha Pest Control', 'Home Maintenance', 'Pest Control', '9000000026', 'Pune', '₹699 - ₹3500', 4.8),
    ('roservice@localconnect.com', 'PureWater RO', 'PureWater RO & Filter Care', 'Home Maintenance', 'RO Water Purifier', '9000000027', 'Pune', '₹299 - ₹1200', 4.9),
    ('locksmith@localconnect.com', 'Chavi Locksmith', 'Master Locksmith & Keys', 'Home Maintenance', 'Locksmith', '9000000028', 'Pune', '₹150 - ₹800', 4.6),
    ('cctv@localconnect.com', 'Vision CCTV', 'Vision CCTV & Security Setup', 'Home Maintenance', 'CCTV & Security', '9000000029', 'Pune', '₹999 - ₹8999', 4.9),

    -- Transport (12)
    ('biketaxi@localconnect.com', 'Akash Bike Rider', 'Speedy Bike Taxi', 'Transport', 'Bike Taxi', '9000000030', 'Pune', '₹30 - ₹150', 4.8),
    ('auto@localconnect.com', 'Santosh Auto', 'City Auto Rickshaw', 'Transport', 'Auto Rickshaw', '9000000031', 'Pune', '₹50 - ₹300', 4.7),
    ('cab@localconnect.com', 'Mohan Cab Driver', 'Mohan Cab Services', 'Transport', 'Mini / Sedan Cab', '9000000018', 'Pune', '₹200 - ₹2000', 4.8),
    ('suv@localconnect.com', 'Rajesh SUV Tours', 'Rajesh Premium SUV Rentals', 'Transport', 'SUV / Ertiga', '9000000032', 'Pune', '₹500 - ₹5000', 4.9),
    ('minitruck@localconnect.com', 'Santosh Tempo', 'Santosh Goods Tempo', 'Transport', 'Mini Truck / Tata Ace', '9000000019', 'Pune', '₹400 - ₹2500', 4.6),
    ('pickuptempo@localconnect.com', 'Balaji Pickup', 'Balaji Pickup Delivery', 'Transport', 'Pickup 8ft / Bolero', '9000000033', 'Pune', '₹600 - ₹3500', 4.7),
    ('largetruck@localconnect.com', 'Maharashtra Transport', 'Maharashtra Heavy Trucking', 'Transport', 'Large Truck (14ft+)', '9000000034', 'Pune', '₹1500 - ₹12000', 4.5),
    ('packers@localconnect.com', 'SafeMove Packers', 'SafeMove Packers & Movers', 'Transport', 'Packers & Movers', '9000000035', 'Pune', '₹2500 - ₹25000', 4.9),
    ('heavyvehicle@localconnect.com', 'Kisan JCB & Crane', 'Kisan Heavy Equipment', 'Transport', 'JCB / Crane / Dumper', '9000000036', 'Pune', '₹1500 - ₹8000/hr', 4.8),
    ('ambulance@localconnect.com', 'LifeLine 24x7', 'LifeLine Emergency Ambulance', 'Transport', 'Emergency Ambulance', '9000000037', 'Pune', '₹500 - ₹3000', 4.9),
    ('tractor@localconnect.com', 'Gramin Agro', 'Gramin Tractor & Trolley', 'Transport', 'Tractor & Trolley', '9000000038', 'Pune', '₹800 - ₹3000', 4.6),
    ('luxurycar@localconnect.com', 'Royal Wedding Cars', 'Royal Wedding Luxury Cars', 'Transport', 'Luxury / Wedding Car', '9000000039', 'Pune', '₹5000 - ₹35000', 4.9),

    -- Events (15)
    ('photography@localconnect.com', 'Deepak Studio', 'Deepak Photography Studio', 'Events', 'Photography', '9000000020', 'Pune', '₹5000 - ₹40000', 4.9),
    ('decoration@localconnect.com', 'Priya Decor', 'Priya Events & Decorators', 'Events', 'Decoration', '9000000021', 'Pune', '₹3000 - ₹30000', 4.8),
    ('sounddj@localconnect.com', 'DJ Rahul', 'DJ Rahul Sound & Bass', 'Events', 'Sound & DJ', '9000000022', 'Pune', '₹4000 - ₹25000', 4.7),
    ('makeup@localconnect.com', 'Kavita Bridal', 'Kavita Bridal & Makeup Studio', 'Events', 'Makeup & Mehendi', '9000000023', 'Pune', '₹1500 - ₹18000', 4.9),
    ('catering@localconnect.com', 'Swad Caterers', 'Swad Royal Caterers', 'Events', 'Catering & Food', '9000000040', 'Pune', '₹250 - ₹1200/plate', 4.8),
    ('mandap@localconnect.com', 'Shree Mandap', 'Shree Mandap & Shamiyana', 'Events', 'Mandap & Shamiyana', '9000000041', 'Pune', '₹5000 - ₹50000', 4.6),
    ('stage@localconnect.com', 'Glow Stage Lights', 'Glow Stage & Truss Setup', 'Events', 'Stage & Lighting', '9000000042', 'Pune', '₹3000 - ₹20000', 4.7),
    ('anchor@localconnect.com', 'Neha Emcee', 'Anchor Neha Event Host', 'Events', 'Anchor / Emcee', '9000000043', 'Pune', '₹3000 - ₹15000', 4.9),
    ('orchestra@localconnect.com', 'Sur Sangeet', 'Sur Sangeet Live Band', 'Events', 'Live Band / Orchestra', '9000000044', 'Pune', '₹8000 - ₹45000', 4.8),
    ('magician@localconnect.com', 'Jadugar Anand', 'Jadugar Anand Kids Magic Show', 'Events', 'Magician / Entertainer', '9000000045', 'Pune', '₹2500 - ₹8000', 4.8),
    ('cake@localconnect.com', 'SweetDelight Cakes', 'SweetDelight Custom Cakes', 'Events', 'Cake & Bakery', '9000000046', 'Pune', '₹450 - ₹3500', 4.9),
    ('invitation@localconnect.com', 'ArtPrint Cards', 'ArtPrint Wedding & Card Print', 'Events', 'Invitation Printing', '9000000047', 'Pune', '₹15 - ₹200/card', 4.7),
    ('valet@localconnect.com', 'Apex Valet', 'Apex Valet Parking Services', 'Events', 'Valet Parking', '9000000048', 'Pune', '₹2000 - ₹15000', 4.8),
    ('generator@localconnect.com', 'PowerGen Rentals', 'PowerGen Silent Generator', 'Events', 'Generator Rental', '9000000049', 'Pune', '₹1500 - ₹10000', 4.7),
    ('chairtable@localconnect.com', 'EventEquip Rentals', 'EventEquip Chairs & Tables', 'Events', 'Chair & Table Rental', '9000000050', 'Pune', '₹10 - ₹200/item', 4.6),

    -- Shop (6)
    ('grocery@localconnect.com', 'Laxmi Kirana', 'Laxmi Super Kirana Store', 'Shop', 'grocery shop', '9000000051', 'Pune', '₹50 - ₹5000', 4.8),
    ('hardware@localconnect.com', 'Bharat Hardware', 'Bharat Electricals & Hardware', 'Shop', 'Electrical & Hardware', '9000000052', 'Pune', '₹100 - ₹8000', 4.7),
    ('meatfish@localconnect.com', 'FreshCatch Meat', 'FreshCatch Chicken, Mutton & Fish', 'Shop', 'Mutton, Chicken & Fish', '9000000053', 'Pune', '₹150 - ₹1200', 4.8),
    ('vegetables@localconnect.com', 'Kisan Fresh Farm', 'Kisan Fresh Vegetables & Fruits', 'Shop', 'Vegetables & Fruits', '9000000054', 'Pune', '₹40 - ₹600', 4.9),
    ('seasonal@localconnect.com', 'Festival World', 'Festival & Seasonal Items Shop', 'Shop', 'Seasonal Items', '9000000055', 'Pune', '₹100 - ₹3000', 4.6),
    ('generalshop@localconnect.com', 'Metro General', 'Metro General & Stationery Store', 'Shop', 'Others', '9000000056', 'Pune', '₹20 - ₹2000', 4.7),

    -- Delivery (10)
    ('fooddelivery@localconnect.com', 'HotBite Express', 'HotBite Food Express', 'Delivery', 'Food Delivery', '9000000057', 'Pune', '₹30 - ₹120', 4.8),
    ('grocerydelivery@localconnect.com', 'QuickKart Delivery', 'QuickKart Instant Grocery Drop', 'Delivery', 'Grocery Delivery', '9000000058', 'Pune', '₹25 - ₹100', 4.8),
    ('medicinedelivery@localconnect.com', 'MedExpress 24x7', 'MedExpress Pharmacy Delivery', 'Delivery', 'Medicine Delivery', '9000000059', 'Pune', '₹20 - ₹80', 4.9),
    ('parcel@localconnect.com', 'CityCourier Runner', 'CityCourier Parcel & Documents', 'Delivery', 'Parcel & Document', '9000000060', 'Pune', '₹40 - ₹250', 4.7),
    ('shoppurchase@localconnect.com', 'AnyStore Buyer', 'AnyStore Personal Shopper & Delivery', 'Delivery', 'Shop Purchase & Delivery', '9000000061', 'Pune', '₹50 - ₹300', 4.8),
    ('pickupdrop@localconnect.com', 'SwiftDrop Runner', 'SwiftDrop Intra-City Pick & Drop', 'Delivery', 'Pickup & Drop', '9000000062', 'Pune', '₹35 - ₹200', 4.8),
    ('heavydelivery@localconnect.com', 'HeavyHaul Cargo', 'HeavyHaul Furniture & Appliances', 'Delivery', 'Heavy Item Delivery', '9000000063', 'Pune', '₹200 - ₹1500', 4.7),
    ('expressdelivery@localconnect.com', 'FlashRunner 15m', 'FlashRunner 15-Minute Express', 'Delivery', 'Express Delivery', '9000000064', 'Pune', '₹50 - ₹180', 4.9),
    ('scheduleddelivery@localconnect.com', 'TimeSlot Logistics', 'TimeSlot Scheduled Drop', 'Delivery', 'Scheduled Delivery', '9000000065', 'Pune', '₹40 - ₹200', 4.7),
    ('intercitydelivery@localconnect.com', 'StateConnect Logistics', 'StateConnect Pune-Mumbai Intercity', 'Delivery', 'Intercity Delivery', '9000000066', 'Pune', '₹150 - ₹1800', 4.8),

    -- Rent (5)
    ('rentroom@localconnect.com', 'GreenHomes Rooms', 'GreenHomes Budget Rental Rooms', 'Rent', 'Room', '9000000067', 'Pune', '₹3000 - ₹12000/mo', 4.7),
    ('pg@localconnect.com', 'ComfortStay PG', 'ComfortStay Boys & Girls PG', 'Rent', 'PG', '9000000068', 'Pune', '₹4500 - ₹9500/mo', 4.8),
    ('hostel@localconnect.com', 'YouthHub Hostel', 'YouthHub Student & Executive Hostel', 'Rent', 'Hostel', '9000000069', 'Pune', '₹3500 - ₹7500/mo', 4.6),
    ('villa@localconnect.com', 'HillView Retreat', 'HillView Luxury Villa & Holiday Home', 'Rent', 'Villa / Holiday Home', '9000000070', 'Pune', '₹4000 - ₹25000/day', 4.9),
    ('toolsrent@localconnect.com', 'ToolMaster Rental', 'ToolMaster Power Tools & Equipment', 'Rent', 'Tools & Equipment', '9000000071', 'Pune', '₹150 - ₹2000/day', 4.8);

  -- 2. Loop and Upsert into auth.users, user_profiles, and service_providers
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
        r.email, pwd_hash,
        now(), now(), now(),
        jsonb_build_object('full_name', r.full_name, 'role', 'provider'),
        jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
        false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null
      );
    ELSE
      new_uid := existing_uid;
      UPDATE auth.users 
      SET encrypted_password = pwd_hash, updated_at = now() 
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

  RAISE NOTICE 'Successfully created and verified all 50+ providers with password Provider@1234!';
END $$;
