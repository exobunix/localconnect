-- Migration: 20260830000005_fix_push_notifications_and_broadcasts.sql
-- Description: Fix notifications schema, drop foreign key constraints, enable broadcast target_audience, and grant open RLS access for Admin & Users.

-- 1. Ensure columns exist on public.notifications
ALTER TABLE public.notifications
  ADD COLUMN IF NOT EXISTS target_audience TEXT DEFAULT 'specific',
  ADD COLUMN IF NOT EXISTS metadata        JSONB DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS type            TEXT DEFAULT 'general',
  ADD COLUMN IF NOT EXISTS is_read         BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS body            TEXT DEFAULT '';

-- 2. Drop blocking NOT NULL or Foreign Key constraints
ALTER TABLE public.notifications ALTER COLUMN user_id DROP NOT NULL;
ALTER TABLE public.notifications DROP CONSTRAINT IF EXISTS notifications_user_id_fkey;

-- 3. Configure Realtime Publication
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

-- 4. Resilient RLS Policies
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "notifications_insert_policy" ON public.notifications;
DROP POLICY IF EXISTS "notifications_insert_own" ON public.notifications;
DROP POLICY IF EXISTS "users_insert_own_notifications" ON public.notifications;
DROP POLICY IF EXISTS "admin_insert_notifications" ON public.notifications;

CREATE POLICY "notifications_insert_policy"
  ON public.notifications FOR INSERT
  TO public
  WITH CHECK (true);

DROP POLICY IF EXISTS "notifications_select_policy" ON public.notifications;
DROP POLICY IF EXISTS "notifications_select_own" ON public.notifications;
DROP POLICY IF EXISTS "users_select_own_notifications" ON public.notifications;
DROP POLICY IF EXISTS "admin_select_notifications" ON public.notifications;

CREATE POLICY "notifications_select_policy"
  ON public.notifications FOR SELECT
  TO public
  USING (true);

DROP POLICY IF EXISTS "notifications_update_policy" ON public.notifications;
DROP POLICY IF EXISTS "notifications_update_own" ON public.notifications;
DROP POLICY IF EXISTS "users_update_own_notifications" ON public.notifications;

CREATE POLICY "notifications_update_policy"
  ON public.notifications FOR UPDATE
  TO public
  USING (true)
  WITH CHECK (true);

DROP POLICY IF EXISTS "notifications_delete_policy" ON public.notifications;
DROP POLICY IF EXISTS "notifications_delete_own" ON public.notifications;
DROP POLICY IF EXISTS "users_delete_own_notifications" ON public.notifications;

CREATE POLICY "notifications_delete_policy"
  ON public.notifications FOR DELETE
  TO public
  USING (true);

-- 5. Grant permissions to all roles
GRANT ALL ON public.notifications TO anon, authenticated, service_role;

-- 6. Reload schema cache
NOTIFY pgrst, 'reload schema';
