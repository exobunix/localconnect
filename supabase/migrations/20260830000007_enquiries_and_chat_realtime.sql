-- ============================================================================
-- Enquiries, Conversations, and Messages RLS and Permissions Fix
-- Idempotent script safe to run multiple times without 42710 errors
-- ============================================================================

-- 1. ENQUIRIES TABLE
CREATE TABLE IF NOT EXISTS public.enquiries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  customer_name TEXT,
  customer_phone TEXT,
  provider_id UUID,
  provider_user_id UUID,
  provider_name TEXT,
  provider_phone TEXT,
  service_title TEXT,
  category TEXT,
  subcategory TEXT,
  preferred_date TEXT,
  preferred_time TEXT,
  message TEXT,
  provider_reply TEXT,
  replied_at TIMESTAMPTZ,
  status TEXT DEFAULT 'pending',
  estimated_price NUMERIC,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Ensure all columns exist on enquiries
ALTER TABLE public.enquiries 
  ADD COLUMN IF NOT EXISTS customer_id UUID,
  ADD COLUMN IF NOT EXISTS customer_name TEXT,
  ADD COLUMN IF NOT EXISTS customer_phone TEXT,
  ADD COLUMN IF NOT EXISTS provider_id UUID,
  ADD COLUMN IF NOT EXISTS provider_user_id UUID,
  ADD COLUMN IF NOT EXISTS provider_name TEXT,
  ADD COLUMN IF NOT EXISTS provider_phone TEXT,
  ADD COLUMN IF NOT EXISTS service_title TEXT,
  ADD COLUMN IF NOT EXISTS category TEXT,
  ADD COLUMN IF NOT EXISTS subcategory TEXT,
  ADD COLUMN IF NOT EXISTS preferred_date TEXT,
  ADD COLUMN IF NOT EXISTS preferred_time TEXT,
  ADD COLUMN IF NOT EXISTS message TEXT,
  ADD COLUMN IF NOT EXISTS provider_reply TEXT,
  ADD COLUMN IF NOT EXISTS replied_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS estimated_price NUMERIC,
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

ALTER TABLE public.enquiries ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "allow_all_enquiries" ON public.enquiries;
CREATE POLICY "allow_all_enquiries"
  ON public.enquiries FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

GRANT ALL ON public.enquiries TO anon, authenticated, service_role;

-- 2. CONVERSATIONS TABLE
CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID,
  provider_id UUID,
  provider_service_id UUID,
  last_message TEXT DEFAULT '',
  last_message_at TIMESTAMPTZ DEFAULT now(),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "allow_all_conversations" ON public.conversations;
CREATE POLICY "allow_all_conversations"
  ON public.conversations FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

GRANT ALL ON public.conversations TO anon, authenticated, service_role;

-- 3. MESSAGES TABLE
CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "allow_all_messages" ON public.messages;
CREATE POLICY "allow_all_messages"
  ON public.messages FOR ALL
  TO public
  USING (true)
  WITH CHECK (true);

GRANT ALL ON public.messages TO anon, authenticated, service_role;

-- 4. Safe Publication Addition (Catches duplicate_object if already added)
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.enquiries;
  EXCEPTION WHEN duplicate_object THEN END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.conversations;
  EXCEPTION WHEN duplicate_object THEN END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  EXCEPTION WHEN duplicate_object THEN END;

  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  EXCEPTION WHEN duplicate_object THEN END;
END $$;

NOTIFY pgrst, 'reload schema';
