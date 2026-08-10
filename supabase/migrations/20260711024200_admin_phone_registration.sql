-- ============================================================
-- Admin Phone Registration Migration
-- Registers +91 9209205923 as the admin mobile number
-- Updates existing admin profile and ensures phone is set.
-- Safe to run multiple times (idempotent).
-- ============================================================

DO $$
DECLARE
  admin_id UUID;
BEGIN
  -- Find existing admin user by role
  SELECT id INTO admin_id
  FROM public.user_profiles
  WHERE role = 'admin'
  LIMIT 1;

  IF admin_id IS NOT NULL THEN
    -- Update the existing admin's phone to +91 9209205923
    UPDATE public.user_profiles
    SET phone = '+919209205923',
        updated_at = now()
    WHERE id = admin_id;

    RAISE NOTICE 'Admin phone updated to +919209205923 for user id: %', admin_id;
  ELSE
    RAISE NOTICE 'No admin user found in user_profiles. Please create an admin account first.';
  END IF;

  -- Also ensure any admin with old placeholder phone gets updated
  UPDATE public.user_profiles
  SET phone = '+919209205923',
      updated_at = now()
  WHERE role = 'admin'
    AND (phone IS NULL OR phone = '9000000000' OR phone = '' OR phone = '+919000000000');

  RAISE NOTICE 'Admin phone registration migration completed.';
END $$;
