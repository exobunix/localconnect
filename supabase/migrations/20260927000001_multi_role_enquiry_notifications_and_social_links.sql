-- Migration: 20260927000001_multi_role_enquiry_notifications_and_social_links.sql
-- Description:
--   1. Adds instagram_url and youtube_url to service_providers and portfolio metadata.
--   2. Adds roles and active_role to user_profiles to allow dual customer & provider accounts for one email and phone number.
--   3. Updates check_phone_registered and check_email_registered to allow customer and provider co-existence.
--   4. Updates notify_on_enquiry_inserted trigger to ensure provider notification alerts are always dispatched reliably with sound/continuous alert.

-- 1. Add social & video link fields to service_providers
ALTER TABLE public.service_providers
  ADD COLUMN IF NOT EXISTS instagram_url TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS youtube_url   TEXT DEFAULT '',
  ADD COLUMN IF NOT EXISTS email         TEXT DEFAULT '';

-- 2. Add dual roles & active_role to user_profiles
ALTER TABLE public.user_profiles
  ADD COLUMN IF NOT EXISTS roles       TEXT[] DEFAULT ARRAY['customer'],
  ADD COLUMN IF NOT EXISTS active_role TEXT DEFAULT 'customer';

-- Populate existing roles array
UPDATE public.user_profiles
SET roles = ARRAY[COALESCE(role, 'customer')]
WHERE roles IS NULL OR array_length(roles, 1) = 0;

-- 3. Update check_phone_registered to allow one customer account and one provider account on same phone
CREATE OR REPLACE FUNCTION public.check_phone_registered(
  phone_num TEXT,
  exclude_user_id UUID DEFAULT NULL,
  target_role TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  cleaned_input TEXT;
  is_exists BOOLEAN;
BEGIN
  cleaned_input := public.normalize_phone(phone_num);
  IF cleaned_input = '' THEN
    RETURN FALSE;
  END IF;

  IF target_role IS NOT NULL AND target_role <> '' THEN
    -- Check if user already exists WITH THAT SAME ROLE
    SELECT EXISTS (
      SELECT 1 FROM public.user_profiles up
      WHERE public.normalize_phone(up.phone) = cleaned_input
        AND (exclude_user_id IS NULL OR up.id != exclude_user_id)
        AND (
          up.role = target_role 
          OR (up.roles IS NOT NULL AND target_role = ANY(up.roles))
          OR (target_role = 'provider' AND EXISTS (
                SELECT 1 FROM public.service_providers sp 
                WHERE sp.user_id = up.id OR public.normalize_phone(sp.phone) = cleaned_input
             ))
        )
    ) INTO is_exists;
  ELSE
    SELECT EXISTS (
      SELECT 1 FROM public.user_profiles up
      WHERE public.normalize_phone(up.phone) = cleaned_input
        AND (exclude_user_id IS NULL OR up.id != exclude_user_id)
    ) INTO is_exists;
  END IF;

  RETURN is_exists;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER search_path = public;

-- 4. Update check_email_registered to allow dual accounts per email
CREATE OR REPLACE FUNCTION public.check_email_registered(
  email_addr TEXT,
  target_role TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  is_exists BOOLEAN;
BEGIN
  IF email_addr IS NULL OR trim(email_addr) = '' THEN
    RETURN FALSE;
  END IF;

  IF target_role IS NOT NULL AND target_role <> '' THEN
    SELECT EXISTS (
      SELECT 1 FROM public.user_profiles up
      WHERE lower(trim(up.email)) = lower(trim(email_addr))
        AND (
          up.role = target_role
          OR (up.roles IS NOT NULL AND target_role = ANY(up.roles))
          OR (target_role = 'provider' AND EXISTS (
                SELECT 1 FROM public.service_providers sp 
                WHERE sp.user_id = up.id OR lower(trim(sp.email)) = lower(trim(email_addr))
             ))
        )
    ) INTO is_exists;
  ELSE
    SELECT EXISTS (
      SELECT 1 FROM public.user_profiles up
      WHERE lower(trim(up.email)) = lower(trim(email_addr))
    ) INTO is_exists;
  END IF;

  RETURN is_exists;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER search_path = public;

-- 5. Resilient enquiry notification trigger
CREATE OR REPLACE FUNCTION public.notify_on_enquiry_inserted()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_provider_user_id UUID;
  v_customer_name TEXT;
  v_service_title TEXT;
  v_provider_name TEXT;
BEGIN
  -- Get customer name
  SELECT COALESCE(full_name, 'A customer') INTO v_customer_name
  FROM public.user_profiles
  WHERE id = NEW.customer_id;

  v_service_title := COALESCE(NEW.service_title, NEW.subcategory, NEW.category, 'Service');
  v_provider_name := COALESCE(NEW.provider_name, 'Service Partner');

  -- Resolve provider user_id
  IF NEW.provider_id IS NOT NULL THEN
    -- Try direct lookup
    SELECT user_id INTO v_provider_user_id
    FROM public.service_providers
    WHERE id = NEW.provider_id OR user_id = NEW.provider_id
    LIMIT 1;
  END IF;

  -- Fallback lookup by provider name or subcategory if provider_id was dummy or not linked
  IF v_provider_user_id IS NULL AND v_provider_name IS NOT NULL AND v_provider_name <> '' THEN
    SELECT user_id INTO v_provider_user_id
    FROM public.service_providers
    WHERE business_name ILIKE v_provider_name OR owner_name ILIKE v_provider_name
    LIMIT 1;
  END IF;

  -- Notify Provider (Ringing alarm alert)
  IF v_provider_user_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, title, body, type, metadata, is_read, created_at)
    VALUES (
      v_provider_user_id,
      '📩 New Customer Enquiry',
      COALESCE(v_customer_name, 'A customer') || ' sent an enquiry for ' || v_service_title || '.',
      'enquiry',
      jsonb_build_object(
        'enquiry_id', NEW.id,
        'customer_id', NEW.customer_id,
        'customer_name', COALESCE(v_customer_name, NEW.customer_name, 'Customer'),
        'customer_phone', COALESCE(NEW.customer_phone, ''),
        'subcategory', v_service_title,
        'service', v_service_title,
        'message', COALESCE(NEW.message, ''),
        'is_continuous_alert', true
      ),
      false,
      now()
    );
  END IF;

  -- Notify Customer (Confirmation)
  IF NEW.customer_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, title, body, type, metadata, is_read, created_at)
    VALUES (
      NEW.customer_id,
      '📨 Enquiry Submitted',
      'Your enquiry for ' || v_service_title || ' has been sent to ' || v_provider_name || '.',
      'enquiry',
      jsonb_build_object(
        'enquiry_id', NEW.id,
        'provider_name', v_provider_name,
        'subcategory', v_service_title
      ),
      false,
      now()
    );
  END IF;

  -- Notify Admin broadcast
  INSERT INTO public.notifications (user_id, target_audience, title, body, type, metadata, is_read, created_at)
  VALUES (
    NULL,
    'admin',
    '📋 New Enquiry Received',
    COALESCE(v_customer_name, 'Customer') || ' ➔ ' || v_provider_name || ' (' || v_service_title || ')',
    'admin_broadcast',
    jsonb_build_object(
      'enquiry_id', NEW.id,
      'provider_name', v_provider_name,
      'customer_name', v_customer_name
    ),
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

NOTIFY pgrst, 'reload schema';
