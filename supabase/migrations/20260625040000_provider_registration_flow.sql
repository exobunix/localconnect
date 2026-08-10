-- Provider Registration Flow Migration
-- Adds registration_status to service_providers and creates category_approval_requests table

-- 1. Add registration_status column to service_providers
ALTER TABLE public.service_providers
ADD COLUMN IF NOT EXISTS registration_status TEXT NOT NULL DEFAULT 'pending_approval';

-- 2. Create category_approval_requests table
CREATE TABLE IF NOT EXISTS public.category_approval_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id UUID UNIQUE REFERENCES public.service_providers(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    category TEXT NOT NULL DEFAULT '',
    subcategory TEXT NOT NULL DEFAULT '',
    reason TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'pending',
    admin_note TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_category_approval_requests_provider_id ON public.category_approval_requests(provider_id);
CREATE INDEX IF NOT EXISTS idx_category_approval_requests_user_id ON public.category_approval_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_category_approval_requests_status ON public.category_approval_requests(status);
CREATE INDEX IF NOT EXISTS idx_service_providers_registration_status ON public.service_providers(registration_status);

-- 4. Enable RLS
ALTER TABLE public.category_approval_requests ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for category_approval_requests
DROP POLICY IF EXISTS "providers_manage_own_approval_requests" ON public.category_approval_requests;
CREATE POLICY "providers_manage_own_approval_requests"
ON public.category_approval_requests
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "admin_manage_all_approval_requests" ON public.category_approval_requests;
CREATE POLICY "admin_manage_all_approval_requests"
ON public.category_approval_requests
FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM auth.users au
        WHERE au.id = auth.uid()
        AND (au.raw_user_meta_data->>'role' = 'admin')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM auth.users au
        WHERE au.id = auth.uid()
        AND (au.raw_user_meta_data->>'role' = 'admin')
    )
);

-- 6. Update existing providers that have onboarding_completed = true to appropriate status
UPDATE public.service_providers
SET registration_status = 'approved'
WHERE onboarding_completed = true AND is_verified = true;

UPDATE public.service_providers
SET registration_status = 'pending_approval'
WHERE onboarding_completed = true AND is_verified = false;
