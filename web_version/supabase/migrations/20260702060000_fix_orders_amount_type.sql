-- Fix orders.amount column type from TEXT to NUMERIC(10,2)
-- This allows proper revenue aggregation and arithmetic operations

DO $$
BEGIN
  -- Check if the column exists and is TEXT type before altering
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'orders'
      AND column_name = 'amount'
      AND data_type = 'text'
  ) THEN
    -- Step 1: Drop the TEXT default ('' cannot be cast to NUMERIC automatically)
    ALTER TABLE public.orders
      ALTER COLUMN amount DROP DEFAULT;

    -- Step 2: Convert TEXT to NUMERIC, treating empty/invalid values as 0
    ALTER TABLE public.orders
      ALTER COLUMN amount TYPE NUMERIC(10,2)
      USING CASE
        WHEN amount IS NULL OR trim(amount) = '' THEN 0
        WHEN amount ~ '^[0-9]+(\.[0-9]+)?$' THEN amount::NUMERIC(10,2)
        ELSE 0
      END;

    -- Step 3: Set a proper NUMERIC default of 0
    ALTER TABLE public.orders
      ALTER COLUMN amount SET DEFAULT 0;

    RAISE NOTICE 'orders.amount column converted from TEXT to NUMERIC(10,2)';
  ELSE
    RAISE NOTICE 'orders.amount is already NUMERIC or does not exist — no change needed';
  END IF;
END $$;
