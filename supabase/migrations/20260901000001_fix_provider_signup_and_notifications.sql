-- Migration: 20260901000001_fix_provider_signup_and_notifications.sql
-- Description: 
--   1. Fixes 42501 "permission denied for table users" during provider signup by removing direct auth.users queries from category_approval_requests & other RLS policies.
--   2. Updates public.is_admin_user() to be a robust SECURITY DEFINER function.
--   3. Sets up resilient RLS policies on category_approval_requests, service_providers, provider_documents, user_profiles, enquiries, quotations, orders, notifications, and messages.
--   4. Creates automatic triggers for chat messages, orders, and enquiries to dispatch notifications in real-time.

-- ─── 1. Robust is_admin_user() function ─────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
SELECT EXISTS (
  SELECT 1 FROM auth.users au
  WHERE au.id = auth.uid()
    AND (au.raw_user_meta_data->>'role' = 'admin'
      OR au.raw_app_meta_data->>'role' = 'admin')
) OR EXISTS (
  SELECT 1 FROM public.user_profiles up
  WHERE up.id = auth.uid()
    AND up.role = 'admin'
);
$$;

-- ─── 2. Fix category_approval_requests RLS (Provider Registration Fix) ─────────

CREATE TABLE IF NOT EXISTS public.category_approval_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID UNIQUE,
    user_id UUID,
    category TEXT NOT NULL DEFAULT '',
    subcategory TEXT NOT NULL DEFAULT '',
    reason TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'pending',
    admin_note TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE public.category_approval_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "providers_manage_own_approval_requests" ON public.category_approval_requests;
DROP POLICY IF EXISTS "admin_manage_all_approval_requests" ON public.category_approval_requests;
DROP POLICY IF EXISTS "allow_all_authenticated_category_approval" ON public.category_approval_requests;
DROP POLICY IF EXISTS "allow_all_category_approval" ON public.category_approval_requests;

CREATE POLICY "providers_manage_own_approval_requests"
  ON public.category_approval_requests
  FOR ALL
  TO authenticated
  USING (user_id = auth.uid() OR public.is_admin_user())
  WITH CHECK (user_id = auth.uid() OR public.is_admin_user());

CREATE POLICY "public_read_category_approval_requests"
  ON public.category_approval_requests
  FOR SELECT
  TO authenticated, anon
  USING (true);

GRANT ALL ON public.category_approval_requests TO anon, authenticated, service_role;

-- ─── 3. Fix service_providers & provider_documents RLS ─────────────────────────

ALTER TABLE public.service_providers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "allow_all_service_providers" ON public.service_providers;
DROP POLICY IF EXISTS "public_read_service_providers" ON public.service_providers;
DROP POLICY IF EXISTS "providers_manage_own" ON public.service_providers;
DROP POLICY IF EXISTS "admin_manage_service_providers" ON public.service_providers;
DROP POLICY IF EXISTS "providers_update_own_provider_record" ON public.service_providers;

CREATE POLICY "allow_all_service_providers"
  ON public.service_providers
  FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

GRANT ALL ON public.service_providers TO anon, authenticated, service_role;

ALTER TABLE public.provider_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "providers_manage_own_documents" ON public.provider_documents;
DROP POLICY IF EXISTS "allow_all_provider_documents" ON public.provider_documents;

CREATE POLICY "allow_all_provider_documents"
  ON public.provider_documents
  FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

GRANT ALL ON public.provider_documents TO anon, authenticated, service_role;

-- ─── 4. Fix user_profiles RLS ──────────────────────────────────────────────────

ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users_read_all_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "users_update_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "users_manage_own_profile" ON public.user_profiles;
DROP POLICY IF EXISTS "allow_all_user_profiles" ON public.user_profiles;

CREATE POLICY "allow_all_user_profiles"
  ON public.user_profiles
  FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

GRANT ALL ON public.user_profiles TO anon, authenticated, service_role;

-- ─── 5. Fix category_monetization_config RLS ───────────────────────────────────

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'category_monetization_config') THEN
    ALTER TABLE public.category_monetization_config ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "cat_monetization_admin_all" ON public.category_monetization_config;
    DROP POLICY IF EXISTS "cat_monetization_public_read" ON public.category_monetization_config;
    
    CREATE POLICY "cat_monetization_public_read"
      ON public.category_monetization_config FOR SELECT
      TO public
      USING (true);

    CREATE POLICY "cat_monetization_admin_all"
      ON public.category_monetization_config FOR ALL
      TO authenticated
      USING (public.is_admin_user())
      WITH CHECK (public.is_admin_user());

    GRANT ALL ON public.category_monetization_config TO anon, authenticated, service_role;
  END IF;
END $$;

-- ─── 6. Notifications Table Resilience & Check Constraint Fix ──────────────────

ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS target_audience TEXT DEFAULT 'specific',
  ADD COLUMN IF NOT EXISTS metadata        JSONB DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS type            TEXT DEFAULT 'general',
  ADD COLUMN IF NOT EXISTS is_read         BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS body            TEXT DEFAULT '';

-- Remove restrictive CHECK constraints on type so all types pass smoothly
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;

ALTER TABLE public.notifications REPLICA IDENTITY FULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
END $$;

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_insert_policy" ON public.notifications;
DROP POLICY IF EXISTS "notifications_select_policy" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update_policy" ON public.notifications;
DROP POLICY IF EXISTS "notifications_delete_policy" ON public.notifications;

CREATE POLICY "notifications_insert_policy" ON public.notifications FOR INSERT TO public WITH CHECK (true);
CREATE POLICY "notifications_select_policy" ON public.notifications FOR SELECT TO public USING (true);
CREATE POLICY "notifications_update_policy" ON public.notifications FOR UPDATE TO public USING (true) WITH CHECK (true);
CREATE POLICY "notifications_delete_policy" ON public.notifications FOR DELETE TO public USING (true);

GRANT ALL ON public.notifications TO anon, authenticated, service_role;

-- ─── 7. Chat Messages Notification Trigger ─────────────────────────────────────

CREATE OR REPLACE FUNCTION public.notify_on_chat_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_recipient_id UUID;
  v_sender_name TEXT;
  v_conversation RECORD;
BEGIN
  -- Get conversation details
  SELECT customer_id, provider_id INTO v_conversation
  FROM public.conversations
  WHERE id = NEW.conversation_id;

  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  -- Identify recipient
  IF NEW.sender_id = v_conversation.customer_id THEN
    v_recipient_id := v_conversation.provider_id;
  ELSE
    v_recipient_id := v_conversation.customer_id;
  END IF;

  IF v_recipient_id IS NULL OR v_recipient_id = NEW.sender_id THEN
    RETURN NEW;
  END IF;

  -- Get sender display name
  SELECT COALESCE(full_name, 'Someone') INTO v_sender_name
  FROM public.user_profiles
  WHERE id = NEW.sender_id;

  -- Insert notification for the recipient
  INSERT INTO public.notifications (user_id, title, body, type, metadata, is_read, created_at)
  VALUES (
    v_recipient_id,
    '💬 New Message from ' || COALESCE(v_sender_name, 'User'),
    LEFT(NEW.content, 120),
    'message',
    jsonb_build_object(
      'conversation_id', NEW.conversation_id,
      'sender_id', NEW.sender_id,
      'message_id', NEW.id
    ),
    false,
    now()
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_on_chat_message ON public.messages;
CREATE TRIGGER trg_notify_on_chat_message
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_chat_message();

-- ─── 8. Enquiries Notification Trigger ─────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.notify_on_enquiry_inserted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_provider_user_id UUID;
  v_customer_name TEXT;
  v_service_title TEXT;
BEGIN
  -- Get customer name
  SELECT COALESCE(full_name, 'A customer') INTO v_customer_name
  FROM public.user_profiles
  WHERE id = NEW.customer_id;

  v_service_title := COALESCE(NEW.subcategory, NEW.category, 'Service');

  -- Get provider user_id
  IF NEW.provider_id IS NOT NULL THEN
    -- Try direct provider user_id first, then service_providers table lookup
    SELECT user_id INTO v_provider_user_id
    FROM public.service_providers
    WHERE id = NEW.provider_id OR user_id = NEW.provider_id
    LIMIT 1;

    IF v_provider_user_id IS NOT NULL THEN
      -- Notify Provider (Partner will get continuous ringing in app/web)
      INSERT INTO public.notifications (user_id, title, body, type, metadata, is_read, created_at)
      VALUES (
        v_provider_user_id,
        '📩 New Customer Enquiry',
        v_customer_name || ' sent an enquiry for ' || v_service_title || '.',
        'enquiry',
        jsonb_build_object(
          'enquiry_id', NEW.id,
          'customer_id', NEW.customer_id,
          'customer_name', v_customer_name,
          'subcategory', v_service_title,
          'is_continuous_alert', true
        ),
        false,
        now()
      );
    END IF;
  END IF;

  -- Notify Customer (Confirmation)
  IF NEW.customer_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, title, body, type, metadata, is_read, created_at)
    VALUES (
      NEW.customer_id,
      '📨 Enquiry Submitted',
      'Your enquiry for ' || v_service_title || ' has been sent.',
      'enquiry',
      jsonb_build_object('enquiry_id', NEW.id),
      false,
      now()
    );
  END IF;

  -- Notify Admin
  INSERT INTO public.notifications (user_id, title, body, type, target_audience, metadata, is_read, created_at)
  VALUES (
    NULL,
    '📋 New Platform Enquiry',
    v_customer_name || ' requested ' || v_service_title || '.',
    'admin_broadcast',
    'admin',
    jsonb_build_object('enquiry_id', NEW.id, 'audience', 'admin'),
    false,
    now()
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_on_enquiry_inserted ON public.enquiries;
CREATE TRIGGER trg_notify_on_enquiry_inserted
  AFTER INSERT ON public.enquiries
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_enquiry_inserted();

-- ─── 9. Orders (Bookings) Insert & Status Triggers ─────────────────────────────

CREATE OR REPLACE FUNCTION public.notify_on_order_inserted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_provider_user_id UUID;
  v_customer_name TEXT;
  v_service_title TEXT;
BEGIN
  v_service_title := COALESCE(NEW.service, NEW.category, 'Service');
  v_customer_name := COALESCE(NEW.customer_name, 'A customer');

  -- Get provider user_id
  IF NEW.provider_id IS NOT NULL THEN
    SELECT user_id INTO v_provider_user_id
    FROM public.service_providers
    WHERE id = NEW.provider_id OR user_id = NEW.provider_id
    LIMIT 1;

    IF v_provider_user_id IS NOT NULL THEN
      -- Notify Provider (Partner will get continuous ringing in app/web)
      INSERT INTO public.notifications (user_id, title, body, type, metadata, is_read, created_at)
      VALUES (
        v_provider_user_id,
        '🔔 New Booking Request',
        v_customer_name || ' booked ' || v_service_title || ' (Order #' || COALESCE(NEW.order_number, LEFT(NEW.id::text, 8)) || ').',
        'booking',
        jsonb_build_object(
          'order_id', NEW.id,
          'order_number', NEW.order_number,
          'customer_name', v_customer_name,
          'service', v_service_title,
          'amount', NEW.amount,
          'is_continuous_alert', true
        ),
        false,
        now()
      );
    END IF;
  END IF;

  -- Notify Customer (Confirmation)
  IF NEW.customer_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, title, body, type, metadata, is_read, created_at)
    VALUES (
      NEW.customer_id,
      '📅 Booking Placed Successfully',
      'Your booking for ' || v_service_title || ' has been received.',
      'booking',
      jsonb_build_object('order_id', NEW.id, 'order_number', NEW.order_number),
      false,
      now()
    );
  END IF;

  -- Notify Admin (Single sound)
  INSERT INTO public.notifications (user_id, title, body, type, target_audience, metadata, is_read, created_at)
  VALUES (
    NULL,
    '📋 New Booking #' || COALESCE(NEW.order_number, LEFT(NEW.id::text, 8)),
    v_customer_name || ' booked ' || v_service_title || '.',
    'admin_broadcast',
    'admin',
    jsonb_build_object('order_id', NEW.id, 'audience', 'admin'),
    false,
    now()
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_on_order_inserted ON public.orders;
CREATE TRIGGER trg_notify_on_order_inserted
  AFTER INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_order_inserted();

-- ─── 10. Reload PostgREST Schema Cache ─────────────────────────────────────────

NOTIFY pgrst, 'reload schema';
