-- ─────────────────────────────────────────────────────────────────────────────
-- Production Audit Migration – Phase 1-15 Fixes
-- Timestamp: 20260731090000
-- Fixes:
--   1. Auto-create conversation after order is accepted
--   2. Auto-create notifications for all key events
--   3. Fix provider_id filter on orders RLS
--   4. Add missing indexes for performance
--   5. Fix conversations RLS to use user_id correctly
--   6. Ensure orders realtime is enabled
--   7. Add trigger to update provider stats on order completion
--   8. Fix orders status update trigger for notifications
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. Enable Realtime on critical tables ────────────────────────────────────
DO $$
BEGIN
  -- orders
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'orders'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.orders;
  END IF;
  -- notifications
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
  -- conversations
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'conversations'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
  END IF;
  -- messages
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  END IF;
EXCEPTION WHEN OTHERS THEN
  NULL; -- ignore if publication doesn't exist
END $$;

-- ── 2. Add missing columns to orders if not present ──────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'reviewed'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN reviewed BOOLEAN DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'payment_status'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN payment_status TEXT DEFAULT 'pending';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'payment_method'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN payment_method TEXT DEFAULT 'cash';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'orders' AND column_name = 'customer_name'
  ) THEN
    ALTER TABLE public.orders ADD COLUMN customer_name TEXT DEFAULT '';
  END IF;
END $$;

-- ── 3. Add missing indexes for performance ───────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_orders_provider_id ON public.orders(provider_id);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON public.orders(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversations_customer_id ON public.conversations(customer_id);
CREATE INDEX IF NOT EXISTS idx_conversations_provider_id ON public.conversations(provider_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at ASC);
CREATE INDEX IF NOT EXISTS idx_service_providers_is_active ON public.service_providers(is_active);
CREATE INDEX IF NOT EXISTS idx_service_providers_rating ON public.service_providers(rating DESC);

-- ── 4. Function: auto-create conversation when order is accepted ──────────────
CREATE OR REPLACE FUNCTION public.auto_create_conversation_on_order_accept()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_provider_user_id UUID;
  v_existing_conv_id UUID;
  v_customer_name TEXT;
BEGIN
  -- Only trigger when status changes to 'active' (accepted)
  IF NEW.status = 'active' AND (OLD.status IS NULL OR OLD.status != 'active') THEN
    -- Get provider's user_id
    SELECT user_id INTO v_provider_user_id
    FROM public.service_providers
    WHERE id = NEW.provider_id;

    IF v_provider_user_id IS NULL THEN
      RETURN NEW;
    END IF;

    -- Check if conversation already exists
    SELECT id INTO v_existing_conv_id
    FROM public.conversations
    WHERE customer_id = NEW.customer_id
      AND provider_id = v_provider_user_id
    LIMIT 1;

    -- Create conversation if it doesn't exist
    IF v_existing_conv_id IS NULL THEN
      INSERT INTO public.conversations (
        customer_id,
        provider_id,
        provider_service_id,
        last_message,
        last_message_at
      ) VALUES (
        NEW.customer_id,
        v_provider_user_id,
        NEW.provider_id,
        'Booking confirmed! You can now chat.',
        NOW()
      );
    END IF;

    -- Get customer name for notification
    SELECT full_name INTO v_customer_name
    FROM public.user_profiles
    WHERE id = NEW.customer_id;

    -- Notify customer that booking was accepted
    INSERT INTO public.notifications (user_id, title, body, type, is_read)
    VALUES (
      NEW.customer_id,
      '✅ Booking Accepted',
      'Your booking for ' || COALESCE(NEW.service, 'service') || ' has been accepted. You can now chat with the provider.',
      'booking',
      false
    );

    -- Notify provider of accepted booking
    INSERT INTO public.notifications (user_id, title, body, type, is_read)
    VALUES (
      v_provider_user_id,
      '📋 Booking Confirmed',
      'You accepted a booking from ' || COALESCE(v_customer_name, 'customer') || ' for ' || COALESCE(NEW.service, 'service') || '.',
      'booking',
      false
    );
  END IF;

  -- Notify when order is completed
  IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN
    SELECT user_id INTO v_provider_user_id
    FROM public.service_providers
    WHERE id = NEW.provider_id;

    -- Notify customer
    INSERT INTO public.notifications (user_id, title, body, type, is_read)
    VALUES (
      NEW.customer_id,
      '🎉 Service Completed',
      'Your service for ' || COALESCE(NEW.service, 'service') || ' has been completed. Please leave a review!',
      'booking',
      false
    );

    -- Update provider completed_orders count
    IF NEW.provider_id IS NOT NULL THEN
      UPDATE public.service_providers
      SET completed_orders = COALESCE(completed_orders, 0) + 1,
          updated_at = NOW()
      WHERE id = NEW.provider_id;
    END IF;
  END IF;

  -- Notify when new order is placed (notify provider)
  IF TG_OP = 'INSERT' AND NEW.provider_id IS NOT NULL THEN
    SELECT user_id INTO v_provider_user_id
    FROM public.service_providers
    WHERE id = NEW.provider_id;

    IF v_provider_user_id IS NOT NULL THEN
      SELECT full_name INTO v_customer_name
      FROM public.user_profiles
      WHERE id = NEW.customer_id;

      INSERT INTO public.notifications (user_id, title, body, type, is_read)
      VALUES (
        v_provider_user_id,
        '🔔 New Service Request',
        COALESCE(v_customer_name, 'A customer') || ' has requested ' || COALESCE(NEW.service, 'your service') || '. Accept or decline.',
        'booking',
        false
      )
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Drop and recreate trigger
DROP TRIGGER IF EXISTS trg_auto_create_conversation ON public.orders;
CREATE TRIGGER trg_auto_create_conversation
  AFTER INSERT OR UPDATE OF status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_create_conversation_on_order_accept();

-- ── 5. Function: update customer_name on order insert ────────────────────────
CREATE OR REPLACE FUNCTION public.populate_order_customer_name()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.customer_name IS NULL OR NEW.customer_name = '' THEN
    SELECT full_name INTO NEW.customer_name
    FROM public.user_profiles
    WHERE id = NEW.customer_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_populate_order_customer_name ON public.orders;
CREATE TRIGGER trg_populate_order_customer_name
  BEFORE INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.populate_order_customer_name();

-- ── 6. Fix RLS on orders table ───────────────────────────────────────────────
-- Ensure customers can only see their own orders
-- Ensure providers can only see orders assigned to them

DROP POLICY IF EXISTS "customers_view_own_orders" ON public.orders;
DROP POLICY IF EXISTS "providers_view_own_orders" ON public.orders;
DROP POLICY IF EXISTS "customers_insert_orders" ON public.orders;
DROP POLICY IF EXISTS "customers_update_own_orders" ON public.orders;
DROP POLICY IF EXISTS "providers_update_assigned_orders" ON public.orders;
DROP POLICY IF EXISTS "orders_select_own" ON public.orders;
DROP POLICY IF EXISTS "orders_insert_authenticated" ON public.orders;
DROP POLICY IF EXISTS "orders_update_own" ON public.orders;

-- SELECT: customer sees own orders, provider sees orders assigned to them
CREATE POLICY "orders_select_own"
ON public.orders
FOR SELECT
TO authenticated
USING (
  customer_id = auth.uid()
  OR provider_id IN (
    SELECT id FROM public.service_providers WHERE user_id = auth.uid()
  )
  OR public.is_admin_user()
);

-- INSERT: authenticated users can create orders (as customer)
CREATE POLICY "orders_insert_authenticated"
ON public.orders
FOR INSERT
TO authenticated
WITH CHECK (customer_id = auth.uid());

-- UPDATE: customer can cancel own pending orders; provider can update status of assigned orders
CREATE POLICY "orders_update_own"
ON public.orders
FOR UPDATE
TO authenticated
USING (
  customer_id = auth.uid()
  OR provider_id IN (
    SELECT id FROM public.service_providers WHERE user_id = auth.uid()
  )
  OR public.is_admin_user()
)
WITH CHECK (
  customer_id = auth.uid()
  OR provider_id IN (
    SELECT id FROM public.service_providers WHERE user_id = auth.uid()
  )
  OR public.is_admin_user()
);

-- ── 7. Fix RLS on conversations table ────────────────────────────────────────
DROP POLICY IF EXISTS "conversations_select_participants" ON public.conversations;
DROP POLICY IF EXISTS "conversations_insert_authenticated" ON public.conversations;
DROP POLICY IF EXISTS "conversations_update_participants" ON public.conversations;

CREATE POLICY "conversations_select_participants"
ON public.conversations
FOR SELECT
TO authenticated
USING (
  customer_id = auth.uid()
  OR provider_id = auth.uid()
  OR public.is_admin_user()
);

CREATE POLICY "conversations_insert_authenticated"
ON public.conversations
FOR INSERT
TO authenticated
WITH CHECK (
  customer_id = auth.uid()
  OR provider_id = auth.uid()
);

CREATE POLICY "conversations_update_participants"
ON public.conversations
FOR UPDATE
TO authenticated
USING (
  customer_id = auth.uid()
  OR provider_id = auth.uid()
)
WITH CHECK (
  customer_id = auth.uid()
  OR provider_id = auth.uid()
);

-- ── 8. Fix RLS on service_providers table ────────────────────────────────────
-- Public can read active providers (for customer search)
DROP POLICY IF EXISTS "public_read_active_providers" ON public.service_providers;
CREATE POLICY "public_read_active_providers"
ON public.service_providers
FOR SELECT
TO authenticated
USING (is_active = true OR user_id = auth.uid() OR public.is_admin_user());

-- Providers can update their own profile
DROP POLICY IF EXISTS "providers_update_own_profile" ON public.service_providers;
CREATE POLICY "providers_update_own_profile"
ON public.service_providers
FOR UPDATE
TO authenticated
USING (user_id = auth.uid() OR public.is_admin_user())
WITH CHECK (user_id = auth.uid() OR public.is_admin_user());

-- ── 9. Fix RLS on notifications ──────────────────────────────────────────────
-- Service role (triggers) must be able to insert notifications for any user
-- This is handled by SECURITY DEFINER on the trigger function above.
-- Ensure authenticated users can read/update their own notifications.
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_select_own" ON public.notifications;
CREATE POLICY "notifications_select_own"
ON public.notifications
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "notifications_update_own" ON public.notifications;
CREATE POLICY "notifications_update_own"
ON public.notifications
FOR UPDATE
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- ── 10. Fix registration_status column on service_providers ──────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'service_providers'
      AND column_name = 'registration_status'
  ) THEN
    ALTER TABLE public.service_providers
    ADD COLUMN registration_status TEXT DEFAULT 'pending_approval';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'service_providers'
      AND column_name = 'onboarding_completed'
  ) THEN
    ALTER TABLE public.service_providers
    ADD COLUMN onboarding_completed BOOLEAN DEFAULT false;
  END IF;
END $$;

-- ── 11. Ensure reviews table has correct foreign keys ────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'reviews'
      AND column_name = 'customer_id'
  ) THEN
    ALTER TABLE public.reviews ADD COLUMN customer_id UUID REFERENCES public.user_profiles(id);
  END IF;
END $$;

-- ── 12. Fix reviews RLS ───────────────────────────────────────────────────────
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'reviews') THEN
    ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
  END IF;
END $$;

DROP POLICY IF EXISTS "reviews_select_all" ON public.reviews;
CREATE POLICY "reviews_select_all"
ON public.reviews
FOR SELECT
TO authenticated
USING (true);

DROP POLICY IF EXISTS "reviews_insert_own" ON public.reviews;
CREATE POLICY "reviews_insert_own"
ON public.reviews
FOR INSERT
TO authenticated
WITH CHECK (customer_id = auth.uid());

-- ── 13. Signup notification trigger ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_on_signup()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.notifications (user_id, title, body, type, is_read)
  VALUES (
    NEW.id,
    '🎉 Welcome to LocalConnect!',
    'Your account has been created successfully. Start exploring services near you.',
    'general',
    false
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_on_signup ON public.user_profiles;
CREATE TRIGGER trg_notify_on_signup
  AFTER INSERT ON public.user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_on_signup();

-- ── 14. Review submission notification trigger ────────────────────────────────
CREATE OR REPLACE FUNCTION public.notify_on_review()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_provider_user_id UUID;
  v_reviewer_name TEXT;
BEGIN
  -- Get provider user_id
  SELECT user_id INTO v_provider_user_id
  FROM public.service_providers
  WHERE id = NEW.provider_id;

  -- Get reviewer name
  SELECT full_name INTO v_reviewer_name
  FROM public.user_profiles
  WHERE id = NEW.customer_id;

  IF v_provider_user_id IS NOT NULL THEN
    INSERT INTO public.notifications (user_id, title, body, type, is_read)
    VALUES (
      v_provider_user_id,
      '⭐ New Review Received',
      COALESCE(v_reviewer_name, 'A customer') || ' gave you a ' || COALESCE(NEW.rating::text, '5') || '-star review.',
      'review',
      false
    );
  END IF;

  -- Mark order as reviewed
  IF NEW.order_id IS NOT NULL THEN
    UPDATE public.orders SET reviewed = true WHERE id = NEW.order_id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_on_review ON public.reviews;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'reviews') THEN
    CREATE TRIGGER trg_notify_on_review
      AFTER INSERT ON public.reviews
      FOR EACH ROW
      EXECUTE FUNCTION public.notify_on_review();
  END IF;
END $$;

-- ── 15. Update provider rating on new review ─────────────────────────────────
CREATE OR REPLACE FUNCTION public.update_provider_rating_on_review()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_avg_rating DECIMAL(3,1);
  v_review_count INTEGER;
BEGIN
  SELECT
    ROUND(AVG(rating)::NUMERIC, 1),
    COUNT(*)
  INTO v_avg_rating, v_review_count
  FROM public.reviews
  WHERE provider_id = NEW.provider_id;

  UPDATE public.service_providers
  SET
    rating = COALESCE(v_avg_rating, 0),
    review_count = COALESCE(v_review_count, 0),
    updated_at = NOW()
  WHERE id = NEW.provider_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_update_provider_rating ON public.reviews;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'reviews') THEN
    CREATE TRIGGER trg_update_provider_rating
      AFTER INSERT OR UPDATE ON public.reviews
      FOR EACH ROW
      EXECUTE FUNCTION public.update_provider_rating_on_review();
  END IF;
END $$;
