-- ============================================================
-- Fix Quotation Schema
-- Timestamp: 20260705180000
-- ============================================================

-- Make enquiry_id and customer_id nullable (quotations can exist without an enquiry, e.g. templates)
ALTER TABLE public.quotations
  ALTER COLUMN enquiry_id DROP NOT NULL;

ALTER TABLE public.quotations
  ALTER COLUMN customer_id DROP NOT NULL;

-- Drop and recreate status constraint to include 'negotiating'
ALTER TABLE public.quotations
  DROP CONSTRAINT IF EXISTS quotations_status_check;

ALTER TABLE public.quotations
  ADD CONSTRAINT quotations_status_check
  CHECK (status = ANY (ARRAY['draft','sent','accepted','rejected','negotiating','expired','completed']));

-- Also fix enquiries status to include 'negotiating'
ALTER TABLE public.enquiries
  DROP CONSTRAINT IF EXISTS enquiries_status_check;

ALTER TABLE public.enquiries
  ADD CONSTRAINT enquiries_status_check
  CHECK (status = ANY (ARRAY['pending','quoted','accepted','rejected','completed','cancelled','negotiating']));
