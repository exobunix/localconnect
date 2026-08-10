-- ─── MESSAGING MODULE ────────────────────────────────────────────────────────
-- Adds conversations and messages tables for real-time chat between customers and providers

-- 1. Conversations table
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    provider_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    provider_service_id UUID REFERENCES public.service_providers(id) ON DELETE SET NULL,
    last_message TEXT DEFAULT '',
    last_message_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_conversations_customer_provider
    ON public.conversations (customer_id, provider_id);

CREATE INDEX IF NOT EXISTS idx_conversations_customer_id ON public.conversations(customer_id);
CREATE INDEX IF NOT EXISTS idx_conversations_provider_id ON public.conversations(provider_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message_at ON public.conversations(last_message_at DESC);

-- 2. Messages table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at ASC);
CREATE INDEX IF NOT EXISTS idx_messages_is_read ON public.messages(is_read);

-- 3. Enable RLS
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for conversations
DROP POLICY IF EXISTS "users_view_own_conversations" ON public.conversations;
CREATE POLICY "users_view_own_conversations"
ON public.conversations
FOR SELECT
TO authenticated
USING (customer_id = auth.uid() OR provider_id = auth.uid());

DROP POLICY IF EXISTS "customers_create_conversations" ON public.conversations;
CREATE POLICY "customers_create_conversations"
ON public.conversations
FOR INSERT
TO authenticated
WITH CHECK (customer_id = auth.uid());

DROP POLICY IF EXISTS "users_update_own_conversations" ON public.conversations;
CREATE POLICY "users_update_own_conversations"
ON public.conversations
FOR UPDATE
TO authenticated
USING (customer_id = auth.uid() OR provider_id = auth.uid())
WITH CHECK (customer_id = auth.uid() OR provider_id = auth.uid());

-- 5. RLS Policies for messages
DROP POLICY IF EXISTS "users_view_conversation_messages" ON public.messages;
CREATE POLICY "users_view_conversation_messages"
ON public.messages
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_id
        AND (c.customer_id = auth.uid() OR c.provider_id = auth.uid())
    )
);

DROP POLICY IF EXISTS "users_send_messages" ON public.messages;
CREATE POLICY "users_send_messages"
ON public.messages
FOR INSERT
TO authenticated
WITH CHECK (
    sender_id = auth.uid()
    AND EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_id
        AND (c.customer_id = auth.uid() OR c.provider_id = auth.uid())
    )
);

DROP POLICY IF EXISTS "users_mark_messages_read" ON public.messages;
CREATE POLICY "users_mark_messages_read"
ON public.messages
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_id
        AND (c.customer_id = auth.uid() OR c.provider_id = auth.uid())
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE c.id = conversation_id
        AND (c.customer_id = auth.uid() OR c.provider_id = auth.uid())
    )
);

-- 6. Function to update conversation last_message on new message
CREATE OR REPLACE FUNCTION public.update_conversation_last_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.conversations
    SET last_message = NEW.content,
        last_message_at = NEW.created_at
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_message_inserted ON public.messages;
CREATE TRIGGER on_message_inserted
    AFTER INSERT ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION public.update_conversation_last_message();

-- 7. Seed demo conversations using existing users
DO $$
DECLARE
    customer_uid UUID;
    provider_uid UUID;
    provider_sp_id UUID;
    conv_id UUID;
BEGIN
    -- Get existing customer user
    SELECT id INTO customer_uid FROM public.user_profiles WHERE role = 'customer' LIMIT 1;
    -- Get existing provider user
    SELECT id INTO provider_uid FROM public.user_profiles WHERE role = 'provider' LIMIT 1;
    -- Get existing service provider record
    SELECT id INTO provider_sp_id FROM public.service_providers LIMIT 1;

    IF customer_uid IS NOT NULL AND provider_uid IS NOT NULL THEN
        -- Create a demo conversation
        INSERT INTO public.conversations (id, customer_id, provider_id, provider_service_id, last_message, last_message_at)
        VALUES (gen_random_uuid(), customer_uid, provider_uid, provider_sp_id, 'Hello! Is your service available today?', now() - interval '5 minutes')
        ON CONFLICT (customer_id, provider_id) DO NOTHING;

        -- Get the conversation id
        SELECT id INTO conv_id FROM public.conversations
        WHERE customer_id = customer_uid AND provider_id = provider_uid
        LIMIT 1;

        IF conv_id IS NOT NULL THEN
            -- Insert demo messages
            INSERT INTO public.messages (id, conversation_id, sender_id, content, is_read, created_at)
            VALUES
                (gen_random_uuid(), conv_id, customer_uid, 'Hello! Is your service available today?', true, now() - interval '10 minutes'),
                (gen_random_uuid(), conv_id, provider_uid, 'Yes, we are available! What time works for you?', true, now() - interval '8 minutes'),
                (gen_random_uuid(), conv_id, customer_uid, 'Can you come at 3 PM?', true, now() - interval '6 minutes'),
                (gen_random_uuid(), conv_id, provider_uid, 'Sure, 3 PM works perfectly. See you then!', false, now() - interval '5 minutes')
            ON CONFLICT (id) DO NOTHING;
        END IF;
    ELSE
        RAISE NOTICE 'No customer or provider users found. Skipping demo messages.';
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Demo messaging data insertion failed: %', SQLERRM;
END $$;
