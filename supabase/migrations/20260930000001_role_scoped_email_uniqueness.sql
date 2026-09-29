-- Migration: 20260930000001_role_scoped_email_uniqueness.sql
-- Description:
--   The original schema had `email TEXT NOT NULL UNIQUE` on user_profiles, which
--   prevented the same email from registering as both a customer AND a provider.
--
--   This migration:
--   1. Drops the global UNIQUE constraint on user_profiles.email.
--   2. Adds a partial unique index per role so each (email, role) combination is
--      still unique — one customer account per email AND one provider per email.
--   3. Ensures active_role defaults correctly for all existing rows.

-- Step 1: Drop the global unique constraint on email
-- The default Postgres name for `email TEXT NOT NULL UNIQUE` is user_profiles_email_key
ALTER TABLE public.user_profiles
  DROP CONSTRAINT IF EXISTS user_profiles_email_key;

-- Step 2: Add per-role partial unique indexes
-- Same email may exist once as 'customer' and once as 'provider'.
CREATE UNIQUE INDEX IF NOT EXISTS uq_user_profiles_email_customer
  ON public.user_profiles (lower(trim(email)))
  WHERE role = 'customer';

CREATE UNIQUE INDEX IF NOT EXISTS uq_user_profiles_email_provider
  ON public.user_profiles (lower(trim(email)))
  WHERE role = 'provider';

-- Step 3: Backfill active_role for any rows where it is still NULL
UPDATE public.user_profiles
SET active_role = role
WHERE active_role IS NULL OR active_role = '';

-- Step 4: Make active_role default to 'customer' for new rows
ALTER TABLE public.user_profiles
  ALTER COLUMN active_role SET DEFAULT 'customer';

-- Step 5: Reload PostgREST schema cache
NOTIFY pgrst, 'reload schema';
