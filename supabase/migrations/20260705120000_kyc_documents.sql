-- KYC Documents for Provider Verification
-- Providers upload Aadhaar, license, business proof
-- Admins review and approve/reject

CREATE TABLE IF NOT EXISTS public.kyc_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id UUID NOT NULL REFERENCES public.service_providers(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  doc_type TEXT NOT NULL CHECK (doc_type IN ('aadhaar', 'license', 'business_proof')),
  doc_url TEXT NOT NULL,
  storage_path TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  rejection_reason TEXT,
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fast lookups
CREATE INDEX IF NOT EXISTS idx_kyc_documents_provider_id ON public.kyc_documents(provider_id);
CREATE INDEX IF NOT EXISTS idx_kyc_documents_status ON public.kyc_documents(status);
CREATE INDEX IF NOT EXISTS idx_kyc_documents_user_id ON public.kyc_documents(user_id);

-- Add kyc_status column to service_providers if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'service_providers'
      AND column_name = 'kyc_status'
  ) THEN
    ALTER TABLE public.service_providers
      ADD COLUMN kyc_status TEXT NOT NULL DEFAULT 'not_submitted'
        CHECK (kyc_status IN ('not_submitted', 'pending', 'approved', 'rejected'));
  END IF;
END $$;

-- RLS Policies
ALTER TABLE public.kyc_documents ENABLE ROW LEVEL SECURITY;

-- Providers can view their own documents
CREATE POLICY "providers_view_own_kyc" ON public.kyc_documents
  FOR SELECT USING (auth.uid() = user_id);

-- Providers can insert their own documents
CREATE POLICY "providers_insert_own_kyc" ON public.kyc_documents
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Providers can update their own pending documents
CREATE POLICY "providers_update_own_pending_kyc" ON public.kyc_documents
  FOR UPDATE USING (auth.uid() = user_id AND status = 'pending');

-- Admins can view all documents
CREATE POLICY "admins_view_all_kyc" ON public.kyc_documents
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admins can update (approve/reject) documents
CREATE POLICY "admins_update_kyc" ON public.kyc_documents
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Storage bucket for KYC documents (private)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'kyc-documents',
  'kyc-documents',
  false,
  5242880, -- 5 MB
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS: providers can upload their own KYC docs
CREATE POLICY "providers_upload_kyc" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'kyc-documents'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Storage RLS: providers can view their own KYC docs
CREATE POLICY "providers_view_own_kyc_storage" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'kyc-documents'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- Storage RLS: admins can view all KYC docs
CREATE POLICY "admins_view_all_kyc_storage" ON storage.objects
  FOR SELECT USING (
    bucket_id = 'kyc-documents'
    AND EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
