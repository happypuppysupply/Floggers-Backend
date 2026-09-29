-- Floggers Database Schema
-- Migration 001: Initial Schema

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- PROFILES (extends auth.users)
-- ============================================
CREATE TABLE public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT,
  avatar_url TEXT,
  role TEXT DEFAULT 'customer' CHECK (role IN ('customer', 'maker', 'admin')),
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles are viewable by everyone"
  ON public.profiles FOR SELECT USING (TRUE);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- ============================================
-- MAKERS
-- ============================================
CREATE TABLE public.makers (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  profile_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  tagline TEXT,
  bio TEXT,
  location TEXT,
  since INTEGER,
  rating DECIMAL(2,1) DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
  products_count INTEGER DEFAULT 0,
  image_url TEXT,
  featured BOOLEAN DEFAULT FALSE,
  is_verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for makers
CREATE INDEX idx_makers_featured ON public.makers(featured);
CREATE INDEX idx_makers_slug ON public.makers(slug);
CREATE INDEX idx_makers_verified ON public.makers(is_verified);

-- RLS for makers
ALTER TABLE public.makers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Makers are viewable by everyone"
  ON public.makers FOR SELECT USING (TRUE);

CREATE POLICY "Users can create own maker profile"
  ON public.makers FOR INSERT WITH CHECK (
    auth.uid() = profile_id AND
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'maker')
  );

CREATE POLICY "Makers can update own profile"
  ON public.makers FOR UPDATE USING (profile_id = auth.uid());

-- ============================================
-- CATEGORIES
-- ============================================
CREATE TABLE public.categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  image_url TEXT,
  sort_order INTEGER DEFAULT 0,
  product_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS for categories (read-only for users)
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Categories are viewable by everyone"
  ON public.categories FOR SELECT USING (TRUE);

-- ============================================
-- PRODUCTS
-- ============================================
CREATE TABLE public.products (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  maker_id UUID REFERENCES public.makers(id) ON DELETE CASCADE NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  category_id TEXT REFERENCES public.categories(id) NOT NULL,
  price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  rating DECIMAL(2,1) DEFAULT 0 CHECK (rating >= 0 AND rating <= 5),
  reviews_count INTEGER DEFAULT 0,
  image_url TEXT,
  images JSONB DEFAULT '[]',
  description TEXT,
  materials JSONB DEFAULT '[]',
  variants JSONB DEFAULT '[]',
  badge TEXT CHECK (badge IN ('bestseller', 'popular', 'most_reviewed')),
  is_active BOOLEAN DEFAULT TRUE,
  stock_count INTEGER DEFAULT 0 CHECK (stock_count >= 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for products
CREATE INDEX idx_products_category ON public.products(category_id);
CREATE INDEX idx_products_maker ON public.products(maker_id);
CREATE INDEX idx_products_active ON public.products(is_active);
CREATE INDEX idx_products_rating ON public.products(rating DESC);
CREATE INDEX idx_products_price ON public.products(price);
CREATE INDEX idx_products_slug ON public.products(slug);
CREATE INDEX idx_products_featured ON public.products(badge, rating DESC) WHERE badge IS NOT NULL;

-- Full-text search index
CREATE INDEX idx_products_search ON public.products 
  USING gin(to_tsvector('english', name || ' ' || COALESCE(description, '')));

-- RLS for products
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Products are viewable by everyone"
  ON public.products FOR SELECT USING (is_active = TRUE OR 
    EXISTS (
      SELECT 1 FROM public.makers m 
      WHERE m.id = products.maker_id AND m.profile_id = auth.uid()
    )
  );

CREATE POLICY "Makers can create products"
  ON public.products FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.makers m 
      WHERE m.id = maker_id AND m.profile_id = auth.uid()
    )
  );

CREATE POLICY "Makers can update own products"
  ON public.products FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.makers m 
      WHERE m.id = products.maker_id AND m.profile_id = auth.uid()
    )
  );

CREATE POLICY "Makers can delete own products"
  ON public.products FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM public.makers m 
      WHERE m.id = products.maker_id AND m.profile_id = auth.uid()
    )
  );

-- ============================================
-- REVIEWS
-- ============================================
CREATE TABLE public.reviews (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  author_name TEXT NOT NULL,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  text TEXT,
  verified BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for reviews
CREATE INDEX idx_reviews_product ON public.reviews(product_id);
CREATE INDEX idx_reviews_user ON public.reviews(user_id);
CREATE INDEX idx_reviews_created ON public.reviews(created_at DESC);

-- RLS for reviews
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Reviews are viewable by everyone"
  ON public.reviews FOR SELECT USING (TRUE);

CREATE POLICY "Authenticated users can create reviews"
  ON public.reviews FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update own reviews"
  ON public.reviews FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete own reviews"
  ON public.reviews FOR DELETE USING (user_id = auth.uid());

-- ============================================
-- CART ITEMS
-- ============================================
CREATE TABLE public.cart_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES public.products(id) ON DELETE CASCADE NOT NULL,
  variant_label TEXT,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, product_id, COALESCE(variant_label, ''))
);

-- Indexes for cart
CREATE INDEX idx_cart_user ON public.cart_items(user_id);
CREATE INDEX idx_cart_product ON public.cart_items(product_id);

-- RLS for cart
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own cart"
  ON public.cart_items FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can add to own cart"
  ON public.cart_items FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own cart items"
  ON public.cart_items FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can remove from own cart"
  ON public.cart_items FOR DELETE USING (user_id = auth.uid());

-- ============================================
-- ORDERS
-- ============================================
CREATE TABLE public.orders (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_number TEXT UNIQUE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')),
  subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
  shipping DECIMAL(10,2) NOT NULL CHECK (shipping >= 0),
  total DECIMAL(10,2) NOT NULL CHECK (total >= 0),
  shipping_address JSONB NOT NULL,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Order items
CREATE TABLE public.order_items (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE NOT NULL,
  product_id UUID REFERENCES public.products(id) ON DELETE SET NULL,
  maker_id UUID REFERENCES public.makers(id) ON DELETE SET NULL,
  product_name TEXT NOT NULL,
  maker_name TEXT NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  variant_label TEXT,
  quantity INTEGER NOT NULL CHECK (quantity > 0)
);

-- Indexes for orders
CREATE INDEX idx_orders_user ON public.orders(user_id);
CREATE INDEX idx_orders_status ON public.orders(status);
CREATE INDEX idx_orders_number ON public.orders(order_number);
CREATE INDEX idx_order_items_order ON public.order_items(order_id);

-- RLS for orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own orders"
  ON public.orders FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can create orders"
  ON public.orders FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Makers can view orders containing their products"
  ON public.orders FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.order_items oi
      JOIN public.makers m ON oi.maker_id = m.id
      WHERE oi.order_id = orders.id AND m.profile_id = auth.uid()
    )
  );

CREATE POLICY "Users can view own order items"
  ON public.order_items FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      WHERE o.id = order_items.order_id AND o.user_id = auth.uid()
    )
  );

CREATE POLICY "Makers can view order items for their products"
  ON public.order_items FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.makers m
      WHERE m.id = order_items.maker_id AND m.profile_id = auth.uid()
    )
  );

-- ============================================
-- FUNCTIONS
-- ============================================

-- Generate order number
CREATE OR REPLACE FUNCTION generate_order_number()
RETURNS TEXT AS $$
BEGIN
  RETURN 'FL-' || LPAD(NEXTVAL('order_number_seq')::TEXT, 5, '0');
END;
$$ LANGUAGE plpgsql;

-- Create sequence for order numbers
CREATE SEQUENCE IF NOT EXISTS order_number_seq START 10000;

-- Auto-generate order number on insert
CREATE OR REPLACE FUNCTION set_order_number()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.order_number IS NULL THEN
    NEW.order_number := generate_order_number();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_order_number
  BEFORE INSERT ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION set_order_number();
