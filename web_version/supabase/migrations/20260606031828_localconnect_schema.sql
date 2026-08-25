-- LocalConnect Full Schema Migration
-- Tables: user_profiles, service_providers, orders, notifications

-- ─── 1. TYPES ────────────────────────────────────────────────────────────────
DROP TYPE IF EXISTS public.user_role CASCADE;
CREATE TYPE public.user_role AS ENUM ('customer', 'provider', 'admin');

DROP TYPE IF EXISTS public.order_status CASCADE;
CREATE TYPE public.order_status AS ENUM ('pending', 'active', 'upcoming', 'completed', 'cancelled');

-- ─── 2. CORE TABLES ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL DEFAULT '',
    phone TEXT DEFAULT '',
    avatar_url TEXT DEFAULT '',
    role public.user_role DEFAULT 'customer'::public.user_role,
    city TEXT DEFAULT 'Pune',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.service_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    business_name TEXT NOT NULL,
    owner_name TEXT NOT NULL DEFAULT '',
    category TEXT NOT NULL,
    subcategory TEXT DEFAULT '',
    description TEXT DEFAULT '',
    phone TEXT DEFAULT '',
    whatsapp TEXT DEFAULT '',
    upi_id TEXT DEFAULT '',
    address TEXT DEFAULT '',
    city TEXT DEFAULT 'Pune',
    rating DECIMAL(3,1) DEFAULT 0.0,
    review_count INTEGER DEFAULT 0,
    completed_orders INTEGER DEFAULT 0,
    price_range TEXT DEFAULT '',
    response_time TEXT DEFAULT '',
    is_open BOOLEAN DEFAULT true,
    open_hours TEXT DEFAULT '9:00 AM - 6:00 PM',
    today_offer TEXT DEFAULT '',
    image_url TEXT DEFAULT '',
    lat DECIMAL(10,7) DEFAULT 18.5204,
    lng DECIMAL(10,7) DEFAULT 73.8567,
    is_verified BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    member_since TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number TEXT NOT NULL UNIQUE,
    customer_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    provider_id UUID REFERENCES public.service_providers(id) ON DELETE SET NULL,
    provider_name TEXT NOT NULL DEFAULT '',
    service TEXT NOT NULL DEFAULT '',
    category TEXT DEFAULT '',
    scheduled_date TEXT DEFAULT '',
    scheduled_time TEXT DEFAULT '',
    amount TEXT DEFAULT '',
    status public.order_status DEFAULT 'pending'::public.order_status,
    rating INTEGER DEFAULT NULL,
    notes TEXT DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    body TEXT NOT NULL DEFAULT '',
    type TEXT DEFAULT 'general',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- ─── 3. INDEXES ──────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_user_profiles_id ON public.user_profiles(id);
CREATE INDEX IF NOT EXISTS idx_service_providers_category ON public.service_providers(category);
CREATE INDEX IF NOT EXISTS idx_service_providers_city ON public.service_providers(city);
CREATE INDEX IF NOT EXISTS idx_service_providers_user_id ON public.service_providers(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);

-- ─── 4. FUNCTIONS ────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.user_profiles (id, email, full_name, phone, avatar_url, role)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'phone', ''),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', ''),
        COALESCE(NEW.raw_user_meta_data->>'role', 'customer')::public.user_role
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT EXISTS (
    SELECT 1 FROM auth.users au
    WHERE au.id = auth.uid()
    AND (au.raw_user_meta_data->>'role' = 'admin' OR au.raw_app_meta_data->>'role' = 'admin')
)
$$;

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- ─── 5. ENABLE RLS ───────────────────────────────────────────────────────────
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_providers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- ─── 6. RLS POLICIES ─────────────────────────────────────────────────────────

-- user_profiles
DROP POLICY IF EXISTS "users_manage_own_user_profiles" ON public.user_profiles;
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles FOR ALL TO authenticated
USING (id = auth.uid()) WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "admin_full_access_user_profiles" ON public.user_profiles;
CREATE POLICY "admin_full_access_user_profiles"
ON public.user_profiles FOR ALL TO authenticated
USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());

-- service_providers: public read, owner write
DROP POLICY IF EXISTS "public_read_service_providers" ON public.service_providers;
CREATE POLICY "public_read_service_providers"
ON public.service_providers FOR SELECT TO public
USING (true);

DROP POLICY IF EXISTS "providers_manage_own" ON public.service_providers;
CREATE POLICY "providers_manage_own"
ON public.service_providers FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "admin_manage_service_providers" ON public.service_providers;
CREATE POLICY "admin_manage_service_providers"
ON public.service_providers FOR ALL TO authenticated
USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());

-- orders
DROP POLICY IF EXISTS "customers_manage_own_orders" ON public.orders;
CREATE POLICY "customers_manage_own_orders"
ON public.orders FOR ALL TO authenticated
USING (customer_id = auth.uid()) WITH CHECK (customer_id = auth.uid());

DROP POLICY IF EXISTS "admin_manage_orders" ON public.orders;
CREATE POLICY "admin_manage_orders"
ON public.orders FOR ALL TO authenticated
USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());

-- notifications
DROP POLICY IF EXISTS "users_manage_own_notifications" ON public.notifications;
CREATE POLICY "users_manage_own_notifications"
ON public.notifications FOR ALL TO authenticated
USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ─── 7. TRIGGERS ─────────────────────────────────────────────────────────────
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

DROP TRIGGER IF EXISTS update_user_profiles_updated_at ON public.user_profiles;
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- ─── 8. MOCK DATA ────────────────────────────────────────────────────────────
DO $$
DECLARE
    admin_uuid UUID := gen_random_uuid();
    customer_uuid UUID := gen_random_uuid();
    provider_uuid UUID := gen_random_uuid();
    prov1_uuid UUID := gen_random_uuid();
    prov2_uuid UUID := gen_random_uuid();
    prov3_uuid UUID := gen_random_uuid();
    prov4_uuid UUID := gen_random_uuid();
    prov5_uuid UUID := gen_random_uuid();
    prov6_uuid UUID := gen_random_uuid();
BEGIN
    -- Create auth users
    INSERT INTO auth.users (
        id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
        created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
        is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
        recovery_token, recovery_sent_at, email_change_token_new, email_change,
        email_change_sent_at, email_change_token_current, email_change_confirm_status,
        reauthentication_token, reauthentication_sent_at, phone, phone_change,
        phone_change_token, phone_change_sent_at
    ) VALUES
        (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'admin@localconnect.com', crypt('admin123', gen_salt('bf', 10)), now(), now(), now(),
         jsonb_build_object('full_name', 'Admin User', 'role', 'admin'),
         jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (customer_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'customer@localconnect.com', crypt('customer123', gen_salt('bf', 10)), now(), now(), now(),
         jsonb_build_object('full_name', 'Rahul Sharma', 'role', 'customer', 'phone', '+91 98765 00001'),
         jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
        (provider_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
         'provider@localconnect.com', crypt('provider123', gen_salt('bf', 10)), now(), now(), now(),
         jsonb_build_object('full_name', 'Suresh Raje', 'role', 'provider', 'phone', '+91 98765 43210'),
         jsonb_build_object('provider', 'email', 'providers', ARRAY['email']::TEXT[]),
         false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null)
    ON CONFLICT (id) DO NOTHING;

    -- Seed service providers
    INSERT INTO public.service_providers (
        id, user_id, business_name, owner_name, category, subcategory, description,
        phone, whatsapp, upi_id, address, city, rating, review_count, completed_orders,
        price_range, response_time, is_open, open_hours, today_offer, image_url,
        lat, lng, is_verified, member_since
    ) VALUES
        (prov1_uuid, provider_uuid, 'Raje Electricals', 'Suresh Raje', 'home_maintenance', 'electrician',
         'Expert electrical repairs, wiring, and installations for homes and offices.',
         '+91 98765 43210', '+91 98765 43210', 'suresh.raje@upi',
         'Shop No. 14, Sadashiv Peth, Near PMC Garden, Pune – 411030',
         'Pune', 4.7, 132, 348, '₹200–800', '~20 min', true, '8:00 AM – 9:00 PM',
         '20% off on all wiring work today! Use code: RAJE20',
         'https://images.pexels.com/photos/257736/pexels-photo-257736.jpeg',
         18.5204, 73.8567, true, 'Jan 2022'),
        (prov2_uuid, null, 'Shree Ganesh Kirana', 'Ganesh Patil', 'shop', 'grocery',
         'Fresh groceries, vegetables, and daily essentials delivered to your door.',
         '+91 98765 43211', '+91 98765 43211', 'ganesh.kirana@upi',
         'Main Market, Deccan Gymkhana, Pune – 411004',
         'Pune', 4.4, 89, 210, '₹50+', '~30 min', true, '7:00 AM – 10:00 PM',
         '',
         'https://images.pexels.com/photos/1367242/pexels-photo-1367242.jpeg',
         18.5167, 73.8478, true, 'Mar 2021'),
        (prov3_uuid, null, 'Priya Beauty Studio', 'Priya Desai', 'beauty', 'salon',
         'Professional beauty services including hair, skin, and makeup treatments.',
         '+91 98765 43212', '+91 98765 43212', 'priya.beauty@upi',
         'FC Road, Shivajinagar, Pune – 411005',
         'Pune', 4.9, 214, 520, '₹299+', 'By Appt.', false, '10:00 AM – 8:00 PM',
         'Flat 15% off on bridal packages this week!',
         'https://images.pexels.com/photos/3997379/pexels-photo-3997379.jpeg',
         18.5308, 73.8474, true, 'Jun 2020'),
        (prov4_uuid, null, 'Mauli Plumbing Works', 'Mauli Jadhav', 'home_maintenance', 'plumber',
         'Reliable plumbing services for leaks, pipe repairs, and installations.',
         '+91 98765 43213', '+91 98765 43213', 'mauli.plumbing@upi',
         'Kothrud, Near Chandani Chowk, Pune – 411038',
         'Pune', 4.3, 67, 180, '₹300–1200', '~45 min', true, '8:00 AM – 8:00 PM',
         '',
         'https://images.pexels.com/photos/8005397/pexels-photo-8005397.jpeg',
         18.5074, 73.8077, false, 'Sep 2022'),
        (prov5_uuid, null, 'Vijay Rickshaw Service', 'Vijay More', 'transport', 'rickshaw',
         'Affordable and reliable auto-rickshaw service across Pune city.',
         '+91 98765 43214', '+91 98765 43214', 'vijay.rickshaw@upi',
         'Swargate Bus Stand, Pune – 411042',
         'Pune', 4.1, 45, 890, '₹30–200', '~5 min', true, '6:00 AM – 11:00 PM',
         '',
         'https://images.pexels.com/photos/1008155/pexels-photo-1008155.jpeg',
         18.4967, 73.8553, false, 'Nov 2021'),
        (prov6_uuid, null, 'Anand Photography', 'Anand Kulkarni', 'events', 'photography',
         'Professional photography for weddings, birthdays, and corporate events.',
         '+91 98765 43215', '+91 98765 43215', 'anand.photo@upi',
         'Aundh, Near ITI College, Pune – 411007',
         'Pune', 4.8, 98, 156, '₹2000+', 'By Appt.', true, '9:00 AM – 7:00 PM',
         'Book now and get free photo album worth ₹500!',
         'https://images.pexels.com/photos/1264210/pexels-photo-1264210.jpeg',
         18.5590, 73.8077, true, 'Feb 2020')
    ON CONFLICT (id) DO NOTHING;

    -- Seed orders for customer
    INSERT INTO public.orders (
        order_number, customer_id, provider_id, provider_name, service, category,
        scheduled_date, scheduled_time, amount, status, rating
    ) VALUES
        ('ORD-2024-001', customer_uuid, prov1_uuid, 'Raje Electricals', 'Fan Repair', 'home_maintenance',
         '10 Apr 2024', '11:00 AM', '₹450', 'completed'::public.order_status, 5),
        ('ORD-2024-002', customer_uuid, prov2_uuid, 'Shree Ganesh Kirana', 'Grocery Order', 'shop',
         '11 Apr 2024', '2:30 PM', '₹820', 'active'::public.order_status, null),
        ('ORD-2024-003', customer_uuid, prov4_uuid, 'Mauli Plumbing Works', 'Pipe Leak Fix', 'home_maintenance',
         '12 Apr 2024', '9:00 AM', '₹600', 'pending'::public.order_status, null),
        ('ORD-2024-004', customer_uuid, prov5_uuid, 'Vijay Rickshaw Service', 'City Ride', 'transport',
         '8 Apr 2024', '8:00 AM', '₹120', 'completed'::public.order_status, 4),
        ('ORD-2024-005', customer_uuid, prov6_uuid, 'Anand Photography', 'Birthday Shoot', 'events',
         '15 Apr 2024', '5:00 PM', '₹3500', 'upcoming'::public.order_status, null),
        ('ORD-2024-006', customer_uuid, null, 'Sai Parcel Delivery', 'Document Delivery', 'delivery',
         '9 Apr 2024', '3:00 PM', '₹80', 'cancelled'::public.order_status, null)
    ON CONFLICT (order_number) DO NOTHING;

    -- Seed notifications for customer
    INSERT INTO public.notifications (user_id, title, body, type, is_read) VALUES
        (customer_uuid, 'Order Confirmed!', 'Your booking with Raje Electricals for Fan Repair has been confirmed.', 'order', false),
        (customer_uuid, 'Provider On The Way', 'Mauli Plumbing Works is on the way to your location.', 'order', false),
        (customer_uuid, 'Special Offer!', 'Priya Beauty Studio is offering 15% off on bridal packages this week!', 'offer', true),
        (customer_uuid, 'Rate Your Experience', 'How was your experience with Vijay Rickshaw Service? Leave a review!', 'review', true),
        (customer_uuid, 'New Provider Nearby', 'Anand Photography just joined LocalConnect in your area!', 'general', false)
    ON CONFLICT (id) DO NOTHING;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Mock data insertion failed: %', SQLERRM;
END $$;
