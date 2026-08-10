-- KYC Extended: Add PAN card, bank account, GST certificate doc types
-- Also adds booking restriction: providers with non-approved KYC cannot accept bookings

-- Step 1: Drop old CHECK constraint on doc_type and add new one with extended types
DO $$
BEGIN
  -- Drop existing constraint if it exists
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND table_name = 'kyc_documents'
      AND constraint_name = 'kyc_documents_doc_type_check'
  ) THEN
    ALTER TABLE public.kyc_documents DROP CONSTRAINT kyc_documents_doc_type_check;
  END IF;

  -- Add new constraint with extended doc types
  ALTER TABLE public.kyc_documents
    ADD CONSTRAINT kyc_documents_doc_type_check
    CHECK (doc_type IN ('aadhaar', 'pan_card', 'license', 'business_proof', 'bank_account', 'gst_certificate'));
END $$;

-- Step 2: Add bank_account_number and gst_number text fields to kyc_documents for structured data
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'kyc_documents'
      AND column_name = 'doc_number'
  ) THEN
    ALTER TABLE public.kyc_documents ADD COLUMN doc_number TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'kyc_documents'
      AND column_name = 'doc_meta'
  ) THEN
    ALTER TABLE public.kyc_documents ADD COLUMN doc_meta JSONB DEFAULT '{}'::jsonb;
  END IF;
END $$;

-- Step 3: Add kyc_verified_at to service_providers for audit trail
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'service_providers'
      AND column_name = 'kyc_verified_at'
  ) THEN
    ALTER TABLE public.service_providers ADD COLUMN kyc_verified_at TIMESTAMPTZ;
  END IF;
END $$;

-- Step 4: Function to check if a provider can accept bookings (KYC must be approved)
CREATE OR REPLACE FUNCTION public.provider_can_accept_bookings(p_provider_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_kyc_status TEXT;
BEGIN
  SELECT kyc_status INTO v_kyc_status
  FROM public.service_providers
  WHERE id = p_provider_id;

  -- Provider can accept bookings only if KYC is approved
  RETURN COALESCE(v_kyc_status = 'approved', FALSE);
END;
$$;

-- Step 5: Update trigger to set kyc_verified_at when status changes to approved
CREATE OR REPLACE FUNCTION public.update_provider_kyc_verified_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.kyc_status = 'approved' AND (OLD.kyc_status IS DISTINCT FROM 'approved') THEN
    NEW.kyc_verified_at = NOW();
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_provider_kyc_verified_at ON public.service_providers;
CREATE TRIGGER trg_provider_kyc_verified_at
  BEFORE UPDATE ON public.service_providers
  FOR EACH ROW
  EXECUTE FUNCTION public.update_provider_kyc_verified_at();

-- Step 6: Index for doc_number lookups
CREATE INDEX IF NOT EXISTS idx_kyc_documents_doc_number ON public.kyc_documents(doc_number) WHERE doc_number IS NOT NULL;
