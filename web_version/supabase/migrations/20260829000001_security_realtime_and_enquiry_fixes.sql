-- Migration: 20260829000001_security_realtime_and_enquiry_fixes.sql
-- Description: Addresses user_profiles 401s, enables realtime for bookings & quotations, and adds missing enquiry columns.

-- 1. Create normalize_phone function
CREATE OR REPLACE FUNCTION public.normalize_phone(phone_input TEXT)
RETURNS TEXT AS $$
DECLARE
  cleaned TEXT;
BEGIN
  IF phone_input IS NULL THEN
    RETURN '';
  END IF;
  -- Remove all non-digits
  cleaned := regexp_replace(phone_input, '\D', '', 'g');
  -- If cleaned starts with 91 and is 12 digits long, strip the 91 country code prefix
  IF length(cleaned) = 12 AND cleaned LIKE '91%' THEN
    cleaned := substring(cleaned from 3);
  -- If it has 11 digits and starts with 0, strip the leading 0
  ELSIF length(cleaned) = 11 AND cleaned LIKE '0%' THEN
    cleaned := substring(cleaned from 2);
  END IF;
  RETURN cleaned;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 2. Create check_phone_registered function (SECURITY DEFINER to bypass table RLS)
CREATE OR REPLACE FUNCTION public.check_phone_registered(phone_num TEXT, exclude_user_id UUID DEFAULT NULL)
RETURNS BOOLEAN AS $$
DECLARE
  cleaned_input TEXT;
  is_exists BOOLEAN;
BEGIN
  cleaned_input := public.normalize_phone(phone_num);
  IF cleaned_input = '' THEN
    RETURN FALSE;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE public.normalize_phone(phone) = cleaned_input
      AND (exclude_user_id IS NULL OR id != exclude_user_id)
  ) INTO is_exists;

  RETURN is_exists;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER search_path = public;

-- 3. Create check_email_registered function (SECURITY DEFINER to bypass table RLS)
CREATE OR REPLACE FUNCTION public.check_email_registered(email_addr TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  is_exists BOOLEAN;
BEGIN
  IF email_addr IS NULL OR email_addr = '' THEN
    RETURN FALSE;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM public.user_profiles
    WHERE lower(email) = lower(trim(email_addr))
  ) INTO is_exists;

  RETURN is_exists;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER search_path = public;

-- 4. Enable Realtime for bookings and quotations
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'bookings'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.bookings;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'quotations'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.quotations;
  END IF;
END $$;

-- 5. Add missing columns to enquiries table
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS customer_name TEXT DEFAULT '';
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS customer_phone TEXT DEFAULT '';
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS provider_name TEXT DEFAULT '';
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS service_title TEXT DEFAULT '';
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS preferred_date TEXT DEFAULT '';
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS preferred_time TEXT DEFAULT '';
ALTER TABLE public.enquiries ADD COLUMN IF NOT EXISTS message TEXT DEFAULT '';
