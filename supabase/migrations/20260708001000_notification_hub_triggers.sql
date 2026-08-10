-- Migration: Add quotation and booking notification types + hub metadata column
-- Safe to run multiple times (idempotent)

-- 1. Add metadata column to notifications if not present
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'notifications'
      AND column_name = 'metadata'
  ) THEN
    ALTER TABLE public.notifications ADD COLUMN metadata jsonb DEFAULT '{}';
  END IF;
END $$;

-- 2. Extend the type CHECK constraint to include quotation and booking types
-- Drop old constraint if it exists, then recreate with extended values
DO $$
BEGIN
  -- Remove old check constraint on type column if present
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints tc
    JOIN information_schema.constraint_column_usage ccu
      ON tc.constraint_name = ccu.constraint_name
    WHERE tc.table_schema = 'public'
      AND tc.table_name = 'notifications'
      AND tc.constraint_type = 'CHECK'
      AND ccu.column_name = 'type'
  ) THEN
    -- Find and drop the constraint
    EXECUTE (
      SELECT 'ALTER TABLE public.notifications DROP CONSTRAINT ' || tc.constraint_name
      FROM information_schema.table_constraints tc
      JOIN information_schema.constraint_column_usage ccu
        ON tc.constraint_name = ccu.constraint_name
      WHERE tc.table_schema = 'public'
        AND tc.table_name = 'notifications'
        AND tc.constraint_type = 'CHECK'
        AND ccu.column_name = 'type'
      LIMIT 1
    );
  END IF;
END $$;

-- Add updated check constraint with all supported types
ALTER TABLE public.notifications
  DROP CONSTRAINT IF EXISTS notifications_type_check;

ALTER TABLE public.notifications
  ADD CONSTRAINT notifications_type_check CHECK (
    type IN (
      'order', 'offer', 'nearby', 'payment', 'review',
      'message', 'quotation', 'booking', 'general'
    )
  );

-- 3. Helper function: insert a notification for a user
CREATE OR REPLACE FUNCTION public.insert_notification(
  p_user_id uuid,
  p_title text,
  p_body text,
  p_type text DEFAULT 'general',
  p_metadata jsonb DEFAULT '{}'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.notifications (user_id, title, body, type, metadata, is_read, created_at)
  VALUES (p_user_id, p_title, p_body, p_type, p_metadata, false, now());
END;
$$;

-- 4. Trigger: notify customer when a quotation is sent to them
CREATE OR REPLACE FUNCTION public.notify_customer_on_quotation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_customer_id uuid;
  v_provider_name text;
BEGIN
  -- Get customer_id from the enquiry linked to this quotation
  SELECT e.customer_id INTO v_customer_id
  FROM public.enquiries e
  WHERE e.id = NEW.enquiry_id;

  IF v_customer_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get provider display name
  SELECT COALESCE(up.full_name, 'A provider') INTO v_provider_name
  FROM public.service_providers sp
  JOIN public.user_profiles up ON up.id = sp.user_id
  WHERE sp.id = NEW.provider_id
  LIMIT 1;

  PERFORM public.insert_notification(
    v_customer_id,
    '📋 New Quotation Received',
    v_provider_name || ' sent you a quotation. Tap to review.',
    'quotation',
    jsonb_build_object('quotation_id', NEW.id, 'enquiry_id', NEW.enquiry_id)
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_customer_on_quotation ON public.quotations;
CREATE TRIGGER trg_notify_customer_on_quotation
  AFTER INSERT ON public.quotations
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_customer_on_quotation();

-- 5. Trigger: notify customer when order (booking) status changes
-- NOTE: Uses public.orders table (the app's booking/order table)
CREATE OR REPLACE FUNCTION public.notify_customer_on_booking_status()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_customer_id uuid;
  v_title text;
  v_body text;
BEGIN
  -- Only fire on status change
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- customer_id is directly on the orders table
  v_customer_id := NEW.customer_id;

  IF v_customer_id IS NULL THEN
    RETURN NEW;
  END IF;

  CASE NEW.status::text
    WHEN 'confirmed' THEN
      v_title := '✅ Booking Confirmed';
      v_body  := 'Your booking has been confirmed by the provider.';
    WHEN 'in_progress' THEN
      v_title := '🔧 Service In Progress';
      v_body  := 'Your service has started.';
    WHEN 'completed' THEN
      v_title := '🎉 Service Completed';
      v_body  := 'Your service is complete. Please leave a review!';
    WHEN 'cancelled' THEN
      v_title := '❌ Booking Cancelled';
      v_body  := 'Your booking has been cancelled.';
    ELSE
      RETURN NEW;
  END CASE;

  PERFORM public.insert_notification(
    v_customer_id,
    v_title,
    v_body,
    'booking',
    jsonb_build_object('order_id', NEW.id, 'status', NEW.status)
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_customer_on_booking_status ON public.orders;
CREATE TRIGGER trg_notify_customer_on_booking_status
  AFTER UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_customer_on_booking_status();

-- 6. Trigger: notify provider when a quotation response (accept/reject) is made
CREATE OR REPLACE FUNCTION public.notify_provider_on_quotation_response()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_provider_user_id uuid;
  v_customer_name text;
  v_title text;
  v_body text;
BEGIN
  IF OLD.status = NEW.status THEN
    RETURN NEW;
  END IF;

  -- Get provider user_id
  SELECT sp.user_id INTO v_provider_user_id
  FROM public.service_providers sp
  WHERE sp.id = NEW.provider_id
  LIMIT 1;

  IF v_provider_user_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get customer name from enquiries table
  SELECT COALESCE(up.full_name, 'Customer') INTO v_customer_name
  FROM public.enquiries e
  JOIN public.user_profiles up ON up.id = e.customer_id
  WHERE e.id = NEW.enquiry_id
  LIMIT 1;

  CASE NEW.status::text
    WHEN 'accepted' THEN
      v_title := '✅ Quotation Accepted';
      v_body  := v_customer_name || ' accepted your quotation!';
    WHEN 'rejected' THEN
      v_title := '❌ Quotation Declined';
      v_body  := v_customer_name || ' declined your quotation.';
    ELSE
      RETURN NEW;
  END CASE;

  PERFORM public.insert_notification(
    v_provider_user_id,
    v_title,
    v_body,
    'message',
    jsonb_build_object('quotation_id', NEW.id, 'status', NEW.status)
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_provider_on_quotation_response ON public.quotations;
CREATE TRIGGER trg_notify_provider_on_quotation_response
  AFTER UPDATE ON public.quotations
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_provider_on_quotation_response();

-- 7. Trigger: notify provider when a review is submitted for their service
CREATE OR REPLACE FUNCTION public.notify_provider_on_review()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_provider_user_id uuid;
  v_customer_name text;
BEGIN
  SELECT sp.user_id INTO v_provider_user_id
  FROM public.service_providers sp
  WHERE sp.id = NEW.provider_id
  LIMIT 1;

  IF v_provider_user_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(up.full_name, 'A customer') INTO v_customer_name
  FROM public.user_profiles up
  WHERE up.id = NEW.customer_id
  LIMIT 1;

  PERFORM public.insert_notification(
    v_provider_user_id,
    '⭐ New Review Received',
    v_customer_name || ' gave you a ' || NEW.rating || '-star review.',
    'review',
    jsonb_build_object('review_id', NEW.id, 'rating', NEW.rating)
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_provider_on_review ON public.reviews;
CREATE TRIGGER trg_notify_provider_on_review
  AFTER INSERT ON public.reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_provider_on_review();
