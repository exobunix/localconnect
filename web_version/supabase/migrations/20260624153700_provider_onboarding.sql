-- Provider Onboarding Migration
-- Adds onboarding_completed flag to service_providers and a documents table

-- 1. Add onboarding_completed column to service_providers
ALTER TABLE public.service_providers
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false;

-- 2. Create provider_documents table
CREATE TABLE IF NOT EXISTS public.provider_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID REFERENCES public.service_providers(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL DEFAULT '',
    document_name TEXT NOT NULL DEFAULT '',
    document_url TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_provider_documents_provider_id ON public.provider_documents(provider_id);
CREATE INDEX IF NOT EXISTS idx_provider_documents_user_id ON public.provider_documents(user_id);

-- 3. Enable RLS
ALTER TABLE public.provider_documents ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies for provider_documents
DROP POLICY IF EXISTS "providers_manage_own_documents" ON public.provider_documents;
CREATE POLICY "providers_manage_own_documents"
ON public.provider_documents
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 5. Function to check if provider onboarding is complete
CREATE OR REPLACE FUNCTION public.is_provider_onboarding_complete(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT COALESCE(
    (SELECT onboarding_completed FROM public.service_providers WHERE user_id = p_user_id LIMIT 1),
    false
)
$$;
