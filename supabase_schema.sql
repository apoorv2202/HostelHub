-- =========================================================================
-- 1. CLEAN SLATE: DROP EVERYTHING IN CORRECT ORDER (No unsafe DROP TRIGGER)
-- =========================================================================
-- A. Drop public tables explicitly
DROP TABLE IF EXISTS public.service_requests CASCADE;
DROP TABLE IF EXISTS public.maintenance_requests CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.lost_requests CASCADE;
DROP TABLE IF EXISTS public.food_stock CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- B. Drop public functions safely (CASCADE drops any triggers using them)
DROP FUNCTION IF EXISTS public.get_user_role CASCADE;
DROP FUNCTION IF EXISTS public.get_user_college CASCADE;
DROP FUNCTION IF EXISTS public.set_first_user_as_admin CASCADE;

-- C. Drop storage policies (Since storage.objects is a system table and can't be dropped)
DROP POLICY IF EXISTS "Users can upload their own cards" ON storage.objects;
DROP POLICY IF EXISTS "Owners, wardens, and admins can view cards" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own cards" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own maintenance images" ON storage.objects;
DROP POLICY IF EXISTS "Owners and wardens can view maintenance images" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own maintenance images" ON storage.objects;

-- =========================================================================
-- 2. EXTENSIONS
-- =========================================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =========================================================================
-- 3. CREATE ALL TABLES FIRST (Explicitly prefixed with public. schema)
-- =========================================================================

-- Profiles (Created first in public schema)
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  name text NOT NULL,
  phone text UNIQUE NOT NULL,
  college text NOT NULL,     -- Every user (including staff) belongs to a college/campus
  
  -- Nullable so Canteen, Cleaners, and Wardens can sign up without room numbers!
  hostel text,               
  room_number text,          

  role text DEFAULT 'student'
    CHECK (role IN ('student','warden','canteen','cleaner','maintenance','admin')),

  verification_status text DEFAULT 'pending'
    CHECK (verification_status IN ('pending','verified','rejected')),

  mess_card_path text,       -- Students upload this, staff leave it blank
  id_card_path text NOT NULL, -- EVERYONE must upload their ID card for verification

  created_at timestamptz DEFAULT now()
);

-- Service Requests
CREATE TABLE public.service_requests (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  cleaning_type text CHECK (cleaning_type IN ('deep_cleaning','normal_cleaning')),
  description text,
  status text DEFAULT 'pending' CHECK (status IN ('pending','accepted','completed')),
  assigned_cleaner uuid REFERENCES public.profiles(id),
  created_at timestamptz DEFAULT now()
);

-- Maintenance Requests
CREATE TABLE public.maintenance_requests (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  category text CHECK (category IN ('electrician','furniture')),
  description text,
  image_urls text[], -- Stores private storage paths
  status text DEFAULT 'pending' CHECK (status IN ('pending','accepted','completed')),
  created_at timestamptz DEFAULT now()
);  

-- Orders (Food Orders)
CREATE TABLE public.orders (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  college text NOT NULL, -- Canteen college (e.g. 'RV', 'BMS')
  items jsonb NOT NULL,
  total_price numeric NOT NULL,
  payment_status text DEFAULT 'pending' CHECK (payment_status IN ('pending','paid')),
  order_status text DEFAULT 'pending' 
    CHECK (order_status IN ('pending','accepted','preparing','ready','completed')),
  created_at timestamptz DEFAULT now()
);

-- Lost Requests
CREATE TABLE public.lost_requests (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  item_type text CHECK (item_type IN ('mess_card','id_card')),
  payment_status text DEFAULT 'pending' CHECK (payment_status IN ('pending','paid')),
  status text DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected','completed')),
  created_at timestamptz DEFAULT now()
);

-- Food Stock
CREATE TABLE public.food_stock (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  food_name text NOT NULL,
  quantity integer DEFAULT 0,
  in_stock boolean GENERATED ALWAYS AS (quantity > 0) STORED,
  updated_at timestamptz DEFAULT now()
);

-- =========================================================================
-- 4. ENABLE ROW LEVEL SECURITY ON ALL TABLES
-- =========================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lost_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_stock ENABLE ROW LEVEL SECURITY;

-- =========================================================================
-- 5. RESILIENT HELPER FUNCTIONS (Explicitly using public. profiles)
-- =========================================================================

-- Get User Role
CREATE OR REPLACE FUNCTION public.get_user_role(user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  user_role text;
BEGIN
  -- Dynamic query completely avoids compile-time table existence checks
  EXECUTE 'SELECT role FROM public.profiles WHERE id = $1'
  INTO user_role
  USING user_id;
  
  RETURN user_role;
END;
$$;

-- Get User College
CREATE OR REPLACE FUNCTION public.get_user_college(user_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  user_college text;
BEGIN
  -- Dynamic query completely avoids compile-time table existence checks
  EXECUTE 'SELECT college FROM public.profiles WHERE id = $1'
  INTO user_college
  USING user_id;
  
  RETURN user_college;
END;
$$;

-- =========================================================================
-- 6. CREATE AUTO-ADMIN TRIGGER
-- =========================================================================
CREATE OR REPLACE FUNCTION public.set_first_user_as_admin()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  profile_exists boolean;
BEGIN
  -- Dynamic check bypasses compilation issues
  EXECUTE 'SELECT EXISTS (SELECT 1 FROM public.profiles)' INTO profile_exists;
  
  -- If there are no existing profiles, make this user the Admin & Auto-Verify them!
  IF NOT profile_exists THEN
    NEW.role := 'admin';
    NEW.verification_status := 'verified';
  END IF;
  RETURN NEW;
END;
$$;

-- Attach trigger to public.profiles table
CREATE TRIGGER set_first_user_admin_trigger
BEFORE INSERT ON public.profiles
FOR EACH ROW
EXECUTE FUNCTION public.set_first_user_as_admin();


-- =========================================================================
-- 7. ROW LEVEL SECURITY POLICIES (Explicitly prefixed)
-- =========================================================================

-- --- PROFILES POLICIES ---
CREATE POLICY "Users view own profile" ON public.profiles 
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users insert own profile during signup" ON public.profiles 
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users update own profile" ON public.profiles 
  FOR UPDATE USING (auth.uid() = id);

-- Staff, Wardens, and Admins can view profiles
CREATE POLICY "Staff, Wardens, and Admins view all profiles" ON public.profiles 
  FOR SELECT USING (public.get_user_role(auth.uid()) IN ('warden', 'admin', 'cleaner', 'canteen', 'maintenance'));

-- Wardens & Admins can update profiles (to change verification_status to verified/rejected)
CREATE POLICY "Wardens and Admins update profiles" ON public.profiles 
  FOR UPDATE USING (public.get_user_role(auth.uid()) IN ('warden', 'admin'));

-- --- SERVICE REQUESTS POLICIES ---
CREATE POLICY "Students view own service requests" ON public.service_requests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Students insert own service requests" ON public.service_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Cleaners can view service requests" ON public.service_requests
  FOR SELECT USING (public.get_user_role(auth.uid()) = 'cleaner');

CREATE POLICY "Cleaners can update assigned service requests" ON public.service_requests
  FOR UPDATE USING (
    public.get_user_role(auth.uid()) = 'cleaner'
    OR auth.uid() = assigned_cleaner 
    OR public.get_user_role(auth.uid()) = 'warden'
  );

-- --- MAINTENANCE REQUESTS POLICIES ---
CREATE POLICY "Students view own maintenance requests" ON public.maintenance_requests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Students insert own maintenance requests" ON public.maintenance_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Wardens can view all maintenance requests" ON public.maintenance_requests
  FOR SELECT USING (public.get_user_role(auth.uid()) = 'warden');

CREATE POLICY "Wardens can update maintenance requests" ON public.maintenance_requests
  FOR UPDATE USING (public.get_user_role(auth.uid()) = 'warden');

-- --- ORDERS POLICIES (Canteen College Restrictions) ---
CREATE POLICY "Students view own orders" ON public.orders
  FOR SELECT USING (auth.uid() = user_id);

-- Enforces that students can only order from their own college's canteen
CREATE POLICY "Students place own orders" ON public.orders
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND college = public.get_user_college(auth.uid())
  );

-- Enforces that canteen staff can only view orders placed to their canteen
CREATE POLICY "Canteen can view food orders" ON public.orders
  FOR SELECT USING (
    public.get_user_role(auth.uid()) = 'canteen'
    AND college = public.get_user_college(auth.uid())
  );

-- Enforces that canteen staff can only update orders of their canteen
CREATE POLICY "Canteen can update food orders" ON public.orders
  FOR UPDATE USING (
    public.get_user_role(auth.uid()) = 'canteen'
    AND college = public.get_user_college(auth.uid())
  );

-- --- LOST REQUESTS POLICIES ---
CREATE POLICY "Students view own lost requests" ON public.lost_requests
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Students insert own lost requests" ON public.lost_requests
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Wardens can view lost requests" ON public.lost_requests
  FOR SELECT USING (public.get_user_role(auth.uid()) = 'warden');

CREATE POLICY "Wardens can update lost requests" ON public.lost_requests
  FOR UPDATE USING (public.get_user_role(auth.uid()) = 'warden');

-- --- FOOD STOCK POLICIES ---
CREATE POLICY "Anyone can view food stock" ON public.food_stock
  FOR SELECT USING (true);

CREATE POLICY "Canteen can manage food stock" ON public.food_stock
  FOR ALL USING (public.get_user_role(auth.uid()) = 'canteen');


-- =========================================================================
-- 8. STORAGE BUCKETS AND STORAGE RLS POLICIES
-- =========================================================================

-- 1. Create Private user_cards Bucket (ID and Mess Cards)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
VALUES (
  'user_cards', 
  'user_cards', 
  false, 
  5242880, 
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- 2. Create Private maintenance_images Bucket (Maintenance Pictures)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) 
VALUES (
  'maintenance_images', 
  'maintenance_images', 
  false, 
  10485760, 
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies: User Cards (Allows Owner, Warden, and Admin to view ID cards)
CREATE POLICY "Users can upload their own cards" ON storage.objects 
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'user_cards' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Owners, wardens, and admins can view cards" ON storage.objects 
  FOR SELECT TO authenticated USING (bucket_id = 'user_cards' AND ((storage.foldername(name))[1] = auth.uid()::text OR public.get_user_role(auth.uid()) IN ('warden', 'admin')));

CREATE POLICY "Users can delete their own cards" ON storage.objects 
  FOR DELETE TO authenticated USING (bucket_id = 'user_cards' AND (storage.foldername(name))[1] = auth.uid()::text);

-- Storage Policies: Maintenance Images (Strictly Private)
CREATE POLICY "Users can upload their own maintenance images" ON storage.objects 
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'maintenance_images' AND (storage.foldername(name))[1] = auth.uid()::text);

CREATE POLICY "Owners and wardens can view maintenance images" ON storage.objects 
  FOR SELECT TO authenticated USING (bucket_id = 'maintenance_images' AND ((storage.foldername(name))[1] = auth.uid()::text OR public.get_user_role(auth.uid()) IN ('warden', 'admin')));

CREATE POLICY "Users can delete their own maintenance images" ON storage.objects 
  FOR DELETE TO authenticated USING (bucket_id = 'maintenance_images' AND (storage.foldername(name))[1] = auth.uid()::text);


-- =========================================================================
-- 9. ENABLE REALTIME
-- =========================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE 
  public.profiles, 
  public.service_requests, 
  public.maintenance_requests, 
  public.orders, 
  public.lost_requests, 
  public.food_stock;
