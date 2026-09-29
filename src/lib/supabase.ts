import { createClient, SupabaseClient } from '@supabase/supabase-js';
import type { 
  Profile, Maker, Category, Product, Review, 
  CartItem, Order, OrderItem,
  ProductListParams, ProductFilters, ProductSort,
  CartItemInput, CreateOrderInput, CreateReviewInput,
  CreateMakerInput, CreateProductInput, UpdateProductInput
} from '../types';

// Environment variables
const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || '';

// Browser client (for client-side usage)
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
  },
});

// Server client (for server-side usage with service role)
export const getServiceSupabase = () => {
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY || '';
  return createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
};

// ============================================
// AUTH FUNCTIONS
// ============================================

export async function signInWithGoogle(redirectTo?: string) {
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: redirectTo || `${window.location.origin}/auth/callback`,
      queryParams: {
        access_type: 'offline',
        prompt: 'consent',
      },
    },
  });
  
  if (error) throw error;
  return data;
}

export async function signOut() {
  const { error } = await supabase.auth.signOut();
  if (error) throw error;
}

export async function getCurrentUser() {
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error) throw error;
  return user;
}

export async function getCurrentSession() {
  const { data: { session }, error } = await supabase.auth.getSession();
  if (error) throw error;
  return session;
}

// ============================================
// PRODUCTS API
// ============================================

export async function getProducts(params: ProductListParams = {}) {
  const { filters, sort = 'featured', page = 1, limit = 20 } = params;
  
  let query = supabase
    .from('products')
    .select('*, maker:makers(*), category:categories(*)')
    .eq('is_active', true);
  
  // Apply filters
  if (filters?.category) {
    query = query.eq('category_id', filters.category);
  }
  
  if (filters?.maker) {
    query = query.eq('maker_id', filters.maker);
  }
  
  if (filters?.minPrice !== undefined) {
    query = query.gte('price', filters.minPrice);
  }
  
  if (filters?.maxPrice !== undefined) {
    query = query.lte('price', filters.maxPrice);
  }
  
  if (filters?.search) {
    // Use the search function for full-text search
    const { data: searchResults, error: searchError } = await supabase.rpc('search_products', {
      query: filters.search,
    });
    
    if (searchError) throw searchError;
    
    // Get full product data for search results
    if (searchResults && searchResults.length > 0) {
      const productIds = searchResults.map((r: { id: string }) => r.id);
      query = query.in('id', productIds);
    } else {
      return { products: [], count: 0 };
    }
  }
  
  // Apply sorting
  switch (sort) {
    case 'price-low':
      query = query.order('price', { ascending: true });
      break;
    case 'price-high':
      query = query.order('price', { ascending: false });
      break;
    case 'rating':
      query = query.order('rating', { ascending: false });
      break;
    case 'reviews':
      query = query.order('reviews_count', { ascending: false });
      break;
    case 'newest':
      query = query.order('created_at', { ascending: false });
      break;
    default: // featured
      query = query.order('badge', { ascending: false, nullsLast: true })
                   .order('rating', { ascending: false });
  }
  
  // Pagination
  const from = (page - 1) * limit;
  const to = from + limit - 1;
  query = query.range(from, to);
  
  const { data, error } = await query;
  
  if (error) throw error;
  
  // Get total count
  const { count, error: countError } = await supabase
    .from('products')
    .select('*', { count: 'exact', head: true })
    .eq('is_active', true);
  
  if (countError) throw countError;
  
  return { products: data as Product[], count: count || 0 };
}

export async function getProductBySlug(slug: string) {
  const { data, error } = await supabase
    .from('products')
    .select('*, maker:makers(*), category:categories(*)')
    .eq('slug', slug)
    .eq('is_active', true)
    .single();
  
  if (error) throw error;
  return data as Product;
}

export async function getProductById(id: string) {
  const { data, error } = await supabase
    .from('products')
    .select('*, maker:makers(*), category:categories(*)')
    .eq('id', id)
    .single();
  
  if (error) throw error;
  return data as Product;
}

export async function createProduct(product: CreateProductInput) {
  const { data, error } = await supabase
    .from('products')
    .insert(product)
    .select()
    .single();
  
  if (error) throw error;
  return data as Product;
}

export async function updateProduct(id: string, updates: UpdateProductInput) {
  const { data, error } = await supabase
    .from('products')
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq('id', id)
    .select()
    .single();
  
  if (error) throw error;
  return data as Product;
}

export async function deleteProduct(id: string) {
  const { error } = await supabase
    .from('products')
    .delete()
    .eq('id', id);
  
  if (error) throw error;
}

// ============================================
// MAKERS API
// ============================================

export async function getMakers(options?: { featured?: boolean; limit?: number }) {
  let query = supabase
    .from('makers')
    .select('*')
    .order('featured', { ascending: false })
    .order('rating', { ascending: false });
  
  if (options?.featured) {
    query = query.eq('featured', true);
  }
  
  if (options?.limit) {
    query = query.limit(options.limit);
  }
  
  const { data, error } = await query;
  
  if (error) throw error;
  return data as Maker[];
}

export async function getMakerBySlug(slug: string) {
  const { data, error } = await supabase
    .from('makers')
    .select('*, products:products(*)')
    .eq('slug', slug)
    .single();
  
  if (error) throw error;
  return data as Maker;
}

export async function getMakerById(id: string) {
  const { data, error } = await supabase
    .from('makers')
    .select('*, products:products(*)')
    .eq('id', id)
    .single();
  
  if (error) throw error;
  return data as Maker;
}

export async function createMaker(maker: CreateMakerInput) {
  const { data, error } = await supabase
    .from('makers')
    .insert(maker)
    .select()
    .single();
  
  if (error) throw error;
  return data as Maker;
}

export async function updateMaker(id: string, updates: Partial<CreateMakerInput>) {
  const { data, error } = await supabase
    .from('makers')
    .update({ ...updates, updated_at: new Date().toISOString() })
    .eq('id', id)
    .select()
    .single();
  
  if (error) throw error;
  return data as Maker;
}

// ============================================
// CATEGORIES API
// ============================================

export async function getCategories() {
  const { data, error } = await supabase
    .from('categories')
    .select('*')
    .order('sort_order', { ascending: true });
  
  if (error) throw error;
  return data as Category[];
}

export async function getCategoryBySlug(slug: string) {
  const { data, error } = await supabase
    .from('categories')
    .select('*, products:products(*)')
    .eq('id', slug)
    .single();
  
  if (error) throw error;
  return data as Category;
}

// ============================================
// REVIEWS API
// ============================================

export async function getProductReviews(productId: string) {
  const { data, error } = await supabase
    .from('reviews')
    .select('*, user:profiles(*)')
    .eq('product_id', productId)
    .order('created_at', { ascending: false });
  
  if (error) throw error;
  return data as Review[];
}

export async function createReview(review: CreateReviewInput) {
  const { data, error } = await supabase
    .from('reviews')
    .insert(review)
    .select()
    .single();
  
  if (error) throw error;
  return data as Review;
}

export async function deleteReview(id: string) {
  const { error } = await supabase
    .from('reviews')
    .delete()
    .eq('id', id);
  
  if (error) throw error;
}

// ============================================
// CART API
// ============================================

export async function getCartItems() {
  const { data, error } = await supabase
    .from('cart_items')
    .select('*, product:products(*)')
    .order('created_at', { ascending: false });
  
  if (error) throw error;
  return data as CartItem[];
}

export async function addToCart(item: CartItemInput) {
  const { data, error } = await supabase
    .from('cart_items')
    .upsert(item, { onConflict: 'user_id,product_id,variant_label' })
    .select()
    .single();
  
  if (error) throw error;
  return data as CartItem;
}

export async function updateCartItem(id: string, quantity: number) {
  const { data, error } = await supabase
    .from('cart_items')
    .update({ quantity })
    .eq('id', id)
    .select()
    .single();
  
  if (error) throw error;
  return data as CartItem;
}

export async function removeFromCart(id: string) {
  const { error } = await supabase
    .from('cart_items')
    .delete()
    .eq('id', id);
  
  if (error) throw error;
}

export async function clearCart() {
  const { error } = await supabase
    .from('cart_items')
    .delete()
    .neq('id', '00000000-0000-0000-0000-000000000000'); // Delete all
  
  if (error) throw error;
}

// ============================================
// ORDERS API
// ============================================

export async function getOrders() {
  const { data, error } = await supabase
    .from('orders')
    .select('*, items:order_items(*, product:products(*))')
    .order('created_at', { ascending: false });
  
  if (error) throw error;
  return data as Order[];
}

export async function getOrderById(id: string) {
  const { data, error } = await supabase
    .from('orders')
    .select('*, items:order_items(*, product:products(*))')
    .eq('id', id)
    .single();
  
  if (error) throw error;
  return data as Order;
}

export async function createOrder(order: CreateOrderInput) {
  // Use the database function to create order from cart
  const { data, error } = await supabase.rpc('create_order_from_cart', {
    p_user_id: (await getCurrentUser())?.id,
    p_shipping_address: order.shipping_address,
    p_shipping_cost: order.shipping_cost || 12,
  });
  
  if (error) throw error;
  return data as string; // Returns order_id
}

export async function getMakerOrders(makerId: string) {
  const { data, error } = await supabase
    .from('order_items')
    .select('*, order:orders(*), product:products(*)')
    .eq('maker_id', makerId)
    .order('created_at', { ascending: false });
  
  if (error) throw error;
  return data as OrderItem[];
}

// ============================================
// STORAGE API
// ============================================

export async function uploadProductImage(file: File, productId: string) {
  const fileExt = file.name.split('.').pop();
  const fileName = `${productId}/${Date.now()}.${fileExt}`;
  
  const { data, error } = await supabase.storage
    .from('products')
    .upload(fileName, file, {
      cacheControl: '3600',
      upsert: false,
    });
  
  if (error) throw error;
  
  // Get public URL
  const { data: { publicUrl } } = supabase.storage
    .from('products')
    .getPublicUrl(data.path);
  
  return publicUrl;
}

export async function uploadMakerImage(file: File, makerId: string) {
  const fileExt = file.name.split('.').pop();
  const fileName = `${makerId}/${Date.now()}.${fileExt}`;
  
  const { data, error } = await supabase.storage
    .from('makers')
    .upload(fileName, file, {
      cacheControl: '3600',
      upsert: false,
    });
  
  if (error) throw error;
  
  const { data: { publicUrl } } = supabase.storage
    .from('makers')
    .getPublicUrl(data.path);
  
  return publicUrl;
}

export async function deleteImage(bucket: 'products' | 'makers', path: string) {
  const { error } = await supabase.storage
    .from(bucket)
    .remove([path]);
  
  if (error) throw error;
}
