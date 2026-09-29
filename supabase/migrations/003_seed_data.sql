-- Migration 003: Seed Data

-- ============================================
-- CATEGORIES
-- ============================================
INSERT INTO categories (id, name, description, image_url, sort_order) VALUES
('floggers', 'Floggers', 'Handcrafted floggers for sensation and impact play', 'https://images.unsplash.com/photo-1615460549969-36fa19521a4f?w=400&h=300&fit=crop', 1),
('paddles', 'Paddles', 'Classic and modern paddles in leather, wood, and acrylic', 'https://images.unsplash.com/photo-1589829085413-56de8ae18c73?w=400&h=300&fit=crop', 2),
('crops', 'Crops & Canes', 'Riding crops, canes, and impact sticks', 'https://images.unsplash.com/photo-1516975080664-ed2fc6a32937?w=400&h=300&fit=crop', 3),
('restraints', 'Restraints & Cuffs', 'Wrist cuffs, ankle cuffs, and restraint systems', 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&h=300&fit=crop', 4),
('collars', 'Collars & Leashes', 'Day collars, play collars, and statement pieces', 'https://images.unsplash.com/photo-1559563362-c667ba5f5480?w=400&h=300&fit=crop', 5),
('accessories', 'Accessories', 'Blindfolds, gags, sensory gear, and more', 'https://images.unsplash.com/photo-1590736969955-71cc94801759?w=400&h=300&fit=crop', 6);

-- ============================================
-- STORAGE BUCKET SETUP (run after storage is enabled)
-- ============================================
-- These need to be run in Supabase dashboard or via API
-- INSERT INTO storage.buckets (id, name, public) VALUES 
--   ('products', 'products', true),
--   ('makers', 'makers', true),
--   ('avatars', 'avatars', true);

-- ============================================
-- SAMPLE DATA FOR DEVELOPMENT
-- Note: These require auth.users to exist first
-- Run these after creating test users
-- ============================================

-- Function to create sample data (run manually after auth setup)
CREATE OR REPLACE FUNCTION seed_sample_data()
RETURNS VOID AS $$
DECLARE
  maker_ids UUID[];
  profile_ids UUID[];
  i INT;
BEGIN
  -- This function is meant to be called after you have auth users
  -- It creates sample makers and products for development
  
  -- Get existing profiles (you need to have signed up users first)
  SELECT ARRAY_AGG(id) INTO profile_ids FROM profiles LIMIT 8;
  
  IF array_length(profile_ids, 1) IS NULL THEN
    RAISE NOTICE 'No profiles found. Sign up users first.';
    RETURN;
  END IF;
  
  -- Create makers
  INSERT INTO makers (profile_id, slug, name, tagline, bio, location, since, rating, featured, is_verified)
  SELECT 
    profile_ids[(i % array_length(profile_ids, 1)) + 1],
    CASE i 
      WHEN 1 THEN 'black-raven-leather'
      WHEN 2 THEN 'iron-heart-forge'
      WHEN 3 THEN 'velvet-noose-ropeworks'
      WHEN 4 THEN 'crimson-crest-designs'
      WHEN 5 THEN 'obsidian-oak'
      WHEN 6 THEN 'midnight-silk-co'
      WHEN 7 THEN 'thorn-rose-studios'
      WHEN 8 THEN 'copper-chain-atelier'
    END,
    CASE i 
      WHEN 1 THEN 'Black Raven Leather'
      WHEN 2 THEN 'Iron Heart Forge'
      WHEN 3 THEN 'Velvet Noose Ropeworks'
      WHEN 4 THEN 'Crimson Crest Designs'
      WHEN 5 THEN 'Obsidian Oak'
      WHEN 6 THEN 'Midnight Silk Co.'
      WHEN 7 THEN 'Thorn & Rose Studios'
      WHEN 8 THEN 'Copper Chain Atelier'
    END,
    CASE i 
      WHEN 1 THEN 'Artisan leather floggers hand-crafted in Portland'
      WHEN 2 THEN 'Steel and fire, forged for play'
      WHEN 3 THEN 'Japanese-inspired rope in silk and jute'
      WHEN 4 THEN 'Bold collars for bold statements'
      WHEN 5 THEN 'Solid hardwood paddles and toys'
      WHEN 6 THEN 'Luxury blindfolds, gags, and sensory gear'
      WHEN 7 THEN 'Electrostimulation and violet wands'
      WHEN 8 THEN 'Chainmail and metal body jewelry'
    END,
    CASE i 
      WHEN 1 THEN 'Founded in 2018, Black Raven Leather specializes in premium BDSM floggers and impact toys crafted from full-grain Italian leather.'
      WHEN 2 THEN 'A metalworking collective creating heavy-duty restraints, spreader bars, and custom dungeon furniture.'
      WHEN 3 THEN 'Specializing in Shibari-grade jute and silk ropes, Velvet Noose sources ethically-produced natural fibers from Japan and India.'
      WHEN 4 THEN 'A woman-owned studio creating statement collars and day collars that blur the line between kink and fashion.'
      WHEN 5 THEN 'Sustainable hardwood impact toys sourced from fallen trees. Each piece is carved, sanded to 600-grit, and finished with food-safe mineral oil.'
      WHEN 6 THEN 'Using deadstock luxury fashion fabrics from Europe, Midnight Silk transforms discarded couture into exquisite sensory deprivation and stimulation gear.'
      WHEN 7 THEN 'Engineer-designed and maker-tested electrostimulation gear. All devices carry CE marking and include comprehensive safety documentation.'
      WHEN 8 THEN 'Traditional chainmail techniques applied to body jewelry and decorative restraints. Custom sizing available for every piece.'
    END,
    CASE i 
      WHEN 1 THEN 'Portland, OR'
      WHEN 2 THEN 'Detroit, MI'
      WHEN 3 THEN 'San Francisco, CA'
      WHEN 4 THEN 'Austin, TX'
      WHEN 5 THEN 'Asheville, NC'
      WHEN 6 THEN 'Brooklyn, NY'
      WHEN 7 THEN 'Seattle, WA'
      WHEN 8 THEN 'New Orleans, LA'
    END,
    2015 + (i * 1),
    4.5 + (i * 0.05),
    i <= 3,
    TRUE
  FROM generate_series(1, 8) AS i
  WHERE i <= array_length(profile_ids, 1)
  RETURNING id INTO maker_ids;
  
  -- Create sample products for each maker
  -- (Product creation would go here)
  
  RAISE NOTICE 'Sample data created successfully';
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PERMISSIONS FOR STORAGE
-- ============================================
-- These policies need to be set in Supabase Dashboard
-- or via storage API

/*
-- Products bucket policies
CREATE POLICY "Product images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'products');

CREATE POLICY "Authenticated makers can upload product images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'products' AND
    auth.role() = 'authenticated'
  );

-- Makers bucket policies  
CREATE POLICY "Maker images are publicly accessible"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'makers');

CREATE POLICY "Authenticated users can upload maker images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'makers' AND
    auth.role() = 'authenticated'
  );
*/
