-- ─── Quotation Negotiation Messages ──────────────────────────────────────────
-- Allows customers and providers to exchange messages, counter-offers,
-- and adjustments on a quotation before it is accepted.

CREATE TABLE IF NOT EXISTS public.quotation_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quotation_id UUID NOT NULL REFERENCES public.quotations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  -- 'text' | 'counter_offer' | 'adjustment' | 'system'
  message_type TEXT NOT NULL DEFAULT 'text',
  content TEXT NOT NULL DEFAULT '',
  -- For counter_offer / adjustment messages
  proposed_amount NUMERIC(12, 2),
  proposed_notes TEXT,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_quotation_messages_quotation_id
  ON public.quotation_messages(quotation_id);

CREATE INDEX IF NOT EXISTS idx_quotation_messages_sender_id
  ON public.quotation_messages(sender_id);

CREATE INDEX IF NOT EXISTS idx_quotation_messages_created_at
  ON public.quotation_messages(created_at DESC);

-- ─── Enable RLS ───────────────────────────────────────────────────────────────
ALTER TABLE public.quotation_messages ENABLE ROW LEVEL SECURITY;

-- ─── RLS Policies ─────────────────────────────────────────────────────────────

-- Participants (customer or provider on the quotation) can read messages
DROP POLICY IF EXISTS "quotation_participants_can_read_messages" ON public.quotation_messages;
CREATE POLICY "quotation_participants_can_read_messages"
  ON public.quotation_messages
  FOR SELECT
  TO authenticated
  USING (
    sender_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.quotations q
      JOIN public.enquiries e ON q.enquiry_id = e.id
      WHERE q.id = quotation_messages.quotation_id
        AND (e.customer_id = auth.uid() OR q.provider_id = (
          SELECT id FROM public.service_providers WHERE user_id = auth.uid() LIMIT 1
        ))
    )
  );

-- Authenticated users can insert their own messages
DROP POLICY IF EXISTS "quotation_participants_can_insert_messages" ON public.quotation_messages;
CREATE POLICY "quotation_participants_can_insert_messages"
  ON public.quotation_messages
  FOR INSERT
  TO authenticated
  WITH CHECK (sender_id = auth.uid());

-- Sender can update their own messages (e.g. mark read)
DROP POLICY IF EXISTS "quotation_participants_can_update_read" ON public.quotation_messages;
CREATE POLICY "quotation_participants_can_update_read"
  ON public.quotation_messages
  FOR UPDATE
  TO authenticated
  USING (
    sender_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.quotations q
      JOIN public.enquiries e ON q.enquiry_id = e.id
      WHERE q.id = quotation_messages.quotation_id
        AND (e.customer_id = auth.uid() OR q.provider_id = (
          SELECT id FROM public.service_providers WHERE user_id = auth.uid() LIMIT 1
        ))
    )
  )
  WITH CHECK (true);
