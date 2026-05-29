-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Clean up any broken tables from previous runs
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.requests CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- PROFILES TABLE
CREATE TABLE public.profiles (
  uuid UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT UNIQUE NOT NULL,
  college TEXT NOT NULL,
  hostel TEXT NOT NULL,
  room_number TEXT NOT NULL,
  verification_status TEXT DEFAULT 'pending',
  mess_card_path TEXT,
  id_card_path TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (uuid)
);

-- REQUESTS TABLE (Cleaning / Maintenance)
CREATE TABLE public.requests (
  id UUID DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(uuid) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('cleaning', 'maintenance')),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT,
  image_path TEXT,
  status TEXT DEFAULT 'pending',
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (id)
);

-- ORDERS TABLE
CREATE TABLE public.orders (
  id UUID DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES public.profiles(uuid) ON DELETE CASCADE,
  items JSONB NOT NULL,
  status TEXT DEFAULT 'preparing',
  total NUMERIC NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (id)
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
CREATE POLICY "Users can view own profile" ON public.profiles FOR SELECT USING (auth.uid() = uuid);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = uuid);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = uuid);

-- Requests Policies
CREATE POLICY "Users can view own requests" ON public.requests FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own requests" ON public.requests FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Orders Policies
CREATE POLICY "Users can view own orders" ON public.orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert own orders" ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);
