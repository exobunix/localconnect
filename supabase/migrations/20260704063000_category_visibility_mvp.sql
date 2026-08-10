-- ─── CATEGORY VISIBILITY MVP LAUNCH MIGRATION ────────────────────────────────
-- Seeds all categories into the categories table with proper visibility.
-- Only Home Maintenance, Transport, and Event Management are active at launch.
-- All other categories are hidden but preserved for future activation.

-- Ensure is_active column exists (idempotent)
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS sort_order INT DEFAULT 0;
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS description TEXT DEFAULT '';
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS icon_name TEXT DEFAULT 'category';
ALTER TABLE public.categories ADD COLUMN IF NOT EXISTS color_hex TEXT DEFAULT '#78909C';

-- Ensure subcategories table has is_active column
ALTER TABLE public.subcategories ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE;

-- ─── SEED / UPSERT ALL CATEGORIES ────────────────────────────────────────────
-- MVP Launch: Only home_maintenance, transport, events are active
-- All others are hidden (is_active = false) but preserved

INSERT INTO public.categories (id, name, name_marathi, icon_name, color_hex, is_active, sort_order, description)
VALUES
  ('home_maintenance', 'Home Maintenance', 'घर देखभाल', 'home_repair_service', '#E65100', TRUE,  1, 'Plumbers, electricians, painters, carpenters and more'),
  ('transport',        'Transport',        'वाहतूक',    'local_taxi',          '#1565C0', TRUE,  2, 'Auto rickshaw, car, truck, tempo and pickup services'),
  ('events',           'Event Management', 'कार्यक्रम व्यवस्थापन', 'celebration', '#6A1B9A', TRUE, 3, 'Photography, catering, decoration, DJ and more'),
  ('shop',             'Shop',             'दुकान',     'storefront',          '#2E7D32', FALSE, 4, 'Grocery, electrical, meat, vegetables and seasonal items'),
  ('delivery',         'Delivery',         'डिलिव्हरी', 'delivery_dining',     '#00838F', FALSE, 5, 'Food, grocery, medicine, parcel and express delivery'),
  ('rent',             'Rent',             'भाड्याने',  'home',                '#4527A0', FALSE, 6, 'Rooms, PG, hostel, villa and tools on rent')
ON CONFLICT (id) DO UPDATE SET
  name         = EXCLUDED.name,
  name_marathi = EXCLUDED.name_marathi,
  icon_name    = EXCLUDED.icon_name,
  color_hex    = EXCLUDED.color_hex,
  is_active    = EXCLUDED.is_active,
  sort_order   = EXCLUDED.sort_order,
  description  = EXCLUDED.description,
  updated_at   = NOW();

-- ─── SEED SUBCATEGORIES ───────────────────────────────────────────────────────

-- Home Maintenance subcategories
INSERT INTO public.subcategories (id, category_id, name, name_marathi, icon_name, sort_order, is_active)
VALUES
  ('plumber',     'home_maintenance', 'Plumber',            'प्लंबर',       'plumbing',              1, TRUE),
  ('electrician', 'home_maintenance', 'Electrician',        'इलेक्ट्रिशन',  'electrical_services',   2, TRUE),
  ('painter',     'home_maintenance', 'Painter',            'रंगारी',        'format_paint',          3, TRUE),
  ('mason',       'home_maintenance', 'Mason',              'गवंडी',         'construction',          4, TRUE),
  ('carpenter',   'home_maintenance', 'Carpenter',          'सुतार',         'carpenter',             5, TRUE),
  ('daily_wage',  'home_maintenance', 'Daily Wage Worker',  'मजूर',          'engineering',           6, TRUE),
  ('cleaning',    'home_maintenance', 'Cleaning Services',  'सफाई सेवा',    'cleaning_services',     7, TRUE)
ON CONFLICT (id) DO UPDATE SET
  category_id  = EXCLUDED.category_id,
  name         = EXCLUDED.name,
  name_marathi = EXCLUDED.name_marathi,
  icon_name    = EXCLUDED.icon_name,
  sort_order   = EXCLUDED.sort_order,
  is_active    = EXCLUDED.is_active;

-- Transport subcategories
INSERT INTO public.subcategories (id, category_id, name, name_marathi, icon_name, sort_order, is_active)
VALUES
  ('rickshaw',   'transport', 'Auto Rickshaw', 'रिक्षा',        'electric_rickshaw', 1, TRUE),
  ('tempo',      'transport', 'Tempo',         'टेम्पो',         'airport_shuttle',   2, TRUE),
  ('pickup_van', 'transport', 'Pickup Van',    'पिकअप व्हॅन',   'local_shipping',    3, TRUE),
  ('truck',      'transport', 'Truck',         'ट्रक',           'fire_truck',        4, TRUE),
  ('car',        'transport', 'Car (Taxi)',     'कार',            'directions_car',    5, TRUE)
ON CONFLICT (id) DO UPDATE SET
  category_id  = EXCLUDED.category_id,
  name         = EXCLUDED.name,
  name_marathi = EXCLUDED.name_marathi,
  icon_name    = EXCLUDED.icon_name,
  sort_order   = EXCLUDED.sort_order,
  is_active    = EXCLUDED.is_active;

-- Event Management subcategories
INSERT INTO public.subcategories (id, category_id, name, name_marathi, icon_name, sort_order, is_active)
VALUES
  ('photography', 'events', 'Photography',        'फोटोग्राफी',      'camera_alt',                1, TRUE),
  ('videography', 'events', 'Videography',        'व्हिडिओग्राफी',   'videocam',                  2, TRUE),
  ('sound',       'events', 'Sound System',       'साउंड सिस्टम',    'speaker',                   3, TRUE),
  ('dj',          'events', 'DJ Services',        'डीजे सेवा',       'music_note',                4, TRUE),
  ('mandap',      'events', 'Mandap Decoration',  'मंडप सजावट',      'temple_hindu',              5, TRUE),
  ('birthday',    'events', 'Birthday Decoration','वाढदिवस सजावट',   'cake',                      6, TRUE),
  ('wedding',     'events', 'Wedding Decoration', 'लग्न सजावट',      'favorite',                  7, TRUE),
  ('balloon',     'events', 'Balloon Decoration', 'फुगे सजावट',      'celebration',               8, TRUE),
  ('flower',      'events', 'Flower Decoration',  'फुल सजावट',       'local_florist',             9, TRUE),
  ('lighting',    'events', 'Lighting Decoration','लाइटिंग सजावट',   'lightbulb',                10, TRUE),
  ('catering',    'events', 'Catering',           'केटरिंग',          'restaurant',               11, TRUE),
  ('mehendi',     'events', 'Mehendi Artist',     'मेहंदी कलाकार',   'brush',                    12, TRUE),
  ('makeup',      'events', 'Makeup Artist',      'मेकअप कलाकार',    'face_retouching_natural',  13, TRUE),
  ('planner',     'events', 'Event Planner',      'इव्हेंट प्लॅनर',  'event_note',               14, TRUE),
  ('anchor',      'events', 'Anchor / Host',      'अँकर / होस्ट',    'mic',                      15, TRUE),
  ('band',        'events', 'Live Band',          'लाइव बँड',         'queue_music',              16, TRUE),
  ('orchestra',   'events', 'Orchestra',          'ऑर्केस्ट्रा',     'piano',                    17, TRUE),
  ('dance',       'events', 'Dance Group',        'नृत्य गट',         'directions_run',           18, TRUE),
  ('generator',   'events', 'Generator Rental',   'जनरेटर भाडे',     'power',                    19, TRUE),
  ('chair_table', 'events', 'Chair & Table Rental','खुर्ची टेबल भाडे','chair',                   20, TRUE),
  ('tent',        'events', 'Tent House',         'तंबू घर',          'holiday_village',          21, TRUE)
ON CONFLICT (id) DO UPDATE SET
  category_id  = EXCLUDED.category_id,
  name         = EXCLUDED.name,
  name_marathi = EXCLUDED.name_marathi,
  icon_name    = EXCLUDED.icon_name,
  sort_order   = EXCLUDED.sort_order,
  is_active    = EXCLUDED.is_active;

-- Shop subcategories (hidden - parent category is_active = false)
INSERT INTO public.subcategories (id, category_id, name, name_marathi, icon_name, sort_order, is_active)
VALUES
  ('grocery',       'shop', 'Grocery / Kirana',         'किराणा',           'shopping_basket',    1, TRUE),
  ('electrical',    'shop', 'Electrical & Hardware',    'इलेक्ट्रिकल',      'electrical_services',2, TRUE),
  ('mutton_chicken','shop', 'Mutton, Chicken & Fish',   'मटण, चिकन, मासे', 'set_meal',           3, TRUE),
  ('vegetables',    'shop', 'Vegetables & Fruits',      'भाजीपाला',         'eco',                4, TRUE),
  ('seasonal',      'shop', 'Seasonal Items',           'हंगामी वस्तू',     'wb_sunny',           5, TRUE),
  ('others_shop',   'shop', 'Others',                   'इतर',              'more_horiz',         6, TRUE)
ON CONFLICT (id) DO UPDATE SET
  category_id  = EXCLUDED.category_id,
  name         = EXCLUDED.name,
  name_marathi = EXCLUDED.name_marathi,
  icon_name    = EXCLUDED.icon_name,
  sort_order   = EXCLUDED.sort_order;

-- Delivery subcategories (hidden)
INSERT INTO public.subcategories (id, category_id, name, name_marathi, icon_name, sort_order, is_active)
VALUES
  ('food',          'delivery', 'Food Delivery',              'फूड डिलिव्हरी',        'fastfood',             1, TRUE),
  ('grocery_del',   'delivery', 'Grocery Delivery',           'किराणा डिलिव्हरी',     'shopping_basket',      2, TRUE),
  ('medicine',      'delivery', 'Medicine Delivery',          'औषध डिलिव्हरी',        'medication',           3, TRUE),
  ('parcel',        'delivery', 'Parcel & Document',          'पार्सल व दस्तऐवज',     'inventory_2',          4, TRUE),
  ('shop_purchase', 'delivery', 'Shop Purchase & Delivery',   'दुकान खरेदी डिलिव्हरी','storefront',           5, TRUE),
  ('pickup_drop',   'delivery', 'Pickup & Drop',              'पिकअप व ड्रॉप',        'swap_horiz',           6, TRUE),
  ('heavy',         'delivery', 'Heavy Item Delivery',        'जड वस्तू डिलिव्हरी',   'inventory',            7, TRUE),
  ('express',       'delivery', 'Express Delivery',           'एक्सप्रेस डिलिव्हरी',  'bolt',                 8, TRUE),
  ('scheduled',     'delivery', 'Scheduled Delivery',         'शेड्युल्ड डिलिव्हरी',  'schedule',             9, TRUE),
  ('intercity',     'delivery', 'Intercity Delivery',         'आंतरशहर डिलिव्हरी',    'connecting_airports', 10, TRUE)
ON CONFLICT (id) DO UPDATE SET
  category_id  = EXCLUDED.category_id,
  name         = EXCLUDED.name,
  name_marathi = EXCLUDED.name_marathi,
  icon_name    = EXCLUDED.icon_name,
  sort_order   = EXCLUDED.sort_order;

-- Rent subcategories (hidden)
INSERT INTO public.subcategories (id, category_id, name, name_marathi, icon_name, sort_order, is_active)
VALUES
  ('room',  'rent', 'Room',              'खोली',  'bedroom_parent', 1, TRUE),
  ('pg',    'rent', 'PG',                'पीजी',   'apartment',      2, TRUE),
  ('hostel','rent', 'Hostel',            'हॉस्टेल','hotel',          3, TRUE),
  ('villa', 'rent', 'Villa / Holiday Home','व्हिला','villa',         4, TRUE),
  ('tools', 'rent', 'Tools & Equipment', 'साधने', 'build',           5, TRUE)
ON CONFLICT (id) DO UPDATE SET
  category_id  = EXCLUDED.category_id,
  name         = EXCLUDED.name,
  name_marathi = EXCLUDED.name_marathi,
  icon_name    = EXCLUDED.icon_name,
  sort_order   = EXCLUDED.sort_order;

-- ─── RLS POLICIES ─────────────────────────────────────────────────────────────

-- Customers/providers: only see active categories
DROP POLICY IF EXISTS "categories_public_read" ON public.categories;
CREATE POLICY "categories_public_read" ON public.categories
  FOR SELECT USING (TRUE); -- filtering done in app layer / service layer

-- Admins can manage categories
DROP POLICY IF EXISTS "categories_admin_all" ON public.categories;
CREATE POLICY "categories_admin_all" ON public.categories
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Subcategories: public read
DROP POLICY IF EXISTS "subcategories_public_read" ON public.subcategories;
CREATE POLICY "subcategories_public_read" ON public.subcategories
  FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "subcategories_admin_all" ON public.subcategories;
CREATE POLICY "subcategories_admin_all" ON public.subcategories
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM public.user_profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Enable RLS
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subcategories ENABLE ROW LEVEL SECURITY;
