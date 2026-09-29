-- Migration 002: Functions and Triggers

-- ============================================
-- AUTO-UPDATE TIMESTAMP FUNCTION
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at
CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_makers_updated_at
  BEFORE UPDATE ON public.makers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_products_updated_at
  BEFORE UPDATE ON public.products
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_cart_items_updated_at
  BEFORE UPDATE ON public.cart_items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- PRODUCT RATING UPDATE
-- ============================================
CREATE OR REPLACE FUNCTION update_product_rating()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    UPDATE products 
    SET 
      rating = COALESCE((
        SELECT ROUND(AVG(rating), 1) 
        FROM reviews 
        WHERE product_id = NEW.product_id
      ), 0),
      reviews_count = (
        SELECT COUNT(*) 
        FROM reviews 
        WHERE product_id = NEW.product_id
      )
    WHERE id = NEW.product_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE products 
    SET 
      rating = COALESCE((
        SELECT ROUND(AVG(rating), 1) 
        FROM reviews 
        WHERE product_id = OLD.product_id
      ), 0),
      reviews_count = (
        SELECT COUNT(*) 
        FROM reviews 
        WHERE product_id = OLD.product_id
      )
    WHERE id = OLD.product_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_product_rating
  AFTER INSERT OR UPDATE OR DELETE ON public.reviews
  FOR EACH ROW
  EXECUTE FUNCTION update_product_rating();

-- ============================================
-- MAKER PRODUCTS COUNT UPDATE
-- ============================================
CREATE OR REPLACE FUNCTION update_maker_products_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE makers 
    SET products_count = (
      SELECT COUNT(*) FROM products WHERE maker_id = NEW.maker_id AND is_active = TRUE
    )
    WHERE id = NEW.maker_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE makers 
    SET products_count = (
      SELECT COUNT(*) FROM products WHERE maker_id = OLD.maker_id AND is_active = TRUE
    )
    WHERE id = OLD.maker_id;
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    -- Handle maker_id change
    IF NEW.maker_id != OLD.maker_id THEN
      UPDATE makers SET products_count = (
        SELECT COUNT(*) FROM products WHERE maker_id = OLD.maker_id AND is_active = TRUE
      ) WHERE id = OLD.maker_id;
      
      UPDATE makers SET products_count = (
        SELECT COUNT(*) FROM products WHERE maker_id = NEW.maker_id AND is_active = TRUE
      ) WHERE id = NEW.maker_id;
    -- Handle is_active change
    ELSIF NEW.is_active != OLD.is_active THEN
      UPDATE makers SET products_count = (
        SELECT COUNT(*) FROM products WHERE maker_id = NEW.maker_id AND is_active = TRUE
      ) WHERE id = NEW.maker_id;
    END IF;
    RETURN NEW;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_maker_products_count
  AFTER INSERT OR DELETE OR UPDATE ON public.products
  FOR EACH ROW
  EXECUTE FUNCTION update_maker_products_count();

-- ============================================
-- MAKER RATING UPDATE (average of all products)
-- ============================================
CREATE OR REPLACE FUNCTION update_maker_rating()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' OR TG_OP = 'UPDATE' THEN
    UPDATE makers 
    SET rating = COALESCE((
      SELECT ROUND(AVG(rating), 1) 
      FROM products 
      WHERE maker_id = NEW.maker_id AND rating > 0
    ), 0)
    WHERE id = NEW.maker_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE makers 
    SET rating = COALESCE((
      SELECT ROUND(AVG(rating), 1) 
      FROM products 
      WHERE maker_id = OLD.maker_id AND rating > 0
    ), 0)
    WHERE id = OLD.maker_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_maker_rating
  AFTER INSERT OR UPDATE OR DELETE ON public.products
  FOR EACH ROW
  EXECUTE FUNCTION update_maker_rating();

-- ============================================
-- CATEGORY PRODUCT COUNT UPDATE
-- ============================================
CREATE OR REPLACE FUNCTION update_category_product_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE categories 
    SET product_count = (
      SELECT COUNT(*) FROM products WHERE category_id = NEW.category_id AND is_active = TRUE
    )
    WHERE id = NEW.category_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE categories 
    SET product_count = (
      SELECT COUNT(*) FROM products WHERE category_id = OLD.category_id AND is_active = TRUE
    )
    WHERE id = OLD.category_id;
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    IF NEW.category_id != OLD.category_id THEN
      UPDATE categories SET product_count = (
        SELECT COUNT(*) FROM products WHERE category_id = OLD.category_id AND is_active = TRUE
      ) WHERE id = OLD.category_id;
      
      UPDATE categories SET product_count = (
        SELECT COUNT(*) FROM products WHERE category_id = NEW.category_id AND is_active = TRUE
      ) WHERE id = NEW.category_id;
    END IF;
    RETURN NEW;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_category_count
  AFTER INSERT OR DELETE OR UPDATE ON public.products
  FOR EACH ROW
  EXECUTE FUNCTION update_category_product_count();

-- ============================================
-- USER PROFILE CREATION ON SIGNUP
-- ============================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, avatar_url)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_create_profile_on_signup
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- ============================================
-- FULL-TEXT SEARCH HELPER
-- ============================================
CREATE OR REPLACE FUNCTION search_products(query TEXT)
RETURNS TABLE(id UUID, name TEXT, maker_name TEXT, category_name TEXT, rank REAL) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.name,
    m.name AS maker_name,
    c.name AS category_name,
    ts_rank(
      to_tsvector('english', p.name || ' ' || COALESCE(p.description, '')),
      plainto_tsquery('english', query)
    ) AS rank
  FROM products p
  JOIN makers m ON p.maker_id = m.id
  JOIN categories c ON p.category_id = c.id
  WHERE p.is_active = TRUE
    AND to_tsvector('english', p.name || ' ' || COALESCE(p.description, '')) @@ plainto_tsquery('english', query)
  ORDER BY rank DESC, p.rating DESC
  LIMIT 20;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- CART TO ORDER CONVERSION
-- ============================================
CREATE OR REPLACE FUNCTION create_order_from_cart(
  p_user_id UUID,
  p_shipping_address JSONB,
  p_shipping_cost DECIMAL DEFAULT 12
)
RETURNS UUID AS $$
DECLARE
  v_order_id UUID;
  v_subtotal DECIMAL(10,2);
  v_total DECIMAL(10,2);
BEGIN
  -- Calculate subtotal
  SELECT COALESCE(SUM(ci.quantity * p.price), 0)
  INTO v_subtotal
  FROM cart_items ci
  JOIN products p ON ci.product_id = p.id
  WHERE ci.user_id = p_user_id;
  
  IF v_subtotal = 0 THEN
    RAISE EXCEPTION 'Cart is empty';
  END IF;
  
  -- Apply free shipping over $150
  IF v_subtotal > 150 THEN
    p_shipping_cost := 0;
  END IF;
  
  v_total := v_subtotal + p_shipping_cost;
  
  -- Create order
  INSERT INTO orders (user_id, subtotal, shipping, total, shipping_address)
  VALUES (p_user_id, v_subtotal, p_shipping_cost, v_total, p_shipping_address)
  RETURNING id INTO v_order_id;
  
  -- Add order items
  INSERT INTO order_items (order_id, product_id, maker_id, product_name, maker_name, price, variant_label, quantity)
  SELECT 
    v_order_id,
    ci.product_id,
    p.maker_id,
    p.name,
    m.name,
    p.price,
    ci.variant_label,
    ci.quantity
  FROM cart_items ci
  JOIN products p ON ci.product_id = p.id
  JOIN makers m ON p.maker_id = m.id
  WHERE ci.user_id = p_user_id;
  
  -- Clear cart
  DELETE FROM cart_items WHERE user_id = p_user_id;
  
  RETURN v_order_id;
END;
$$ LANGUAGE plpgsql;
