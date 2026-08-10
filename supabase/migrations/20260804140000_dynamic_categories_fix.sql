-- ─── DYNAMIC CATEGORIES FIX MIGRATION ───────────────────────────────────────
-- Ensures subcategories table has updated_at column for toggle operations.
-- Seeds the "Waterproofing" subcategory under Home Maintenance.
-- Fixes: newly added subcategories now appear in app without code changes.

-- Add updated_at to subcategories if missing
ALTER TABLE public.subcategories ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Add sort_order to subcategories if missing (already exists but idempotent)
ALTER TABLE public.subcategories ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 99;

-- Seed Waterproofing subcategory under Home Maintenance
INSERT INTO public.subcategories (id, category_id, name, name_marathi, icon_name, sort_order, is_active)
VALUES
  ('waterproofing', 'home_maintenance', 'Waterproofing', 'वॉटरप्रूफिंग', 'water_damage', 8, TRUE)
ON CONFLICT (id) DO UPDATE SET
  category_id  = EXCLUDED.category_id,
  name         = EXCLUDED.name,
  name_marathi = EXCLUDED.name_marathi,
  icon_name    = EXCLUDED.icon_name,
  sort_order   = EXCLUDED.sort_order,
  is_active    = EXCLUDED.is_active,
  updated_at   = NOW();
