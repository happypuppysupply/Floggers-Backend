// Floggers TypeScript Types
// Mirrors the database schema for type safety

export type UserRole = 'customer' | 'maker' | 'admin';

export interface Profile {
  id: string;
  email: string;
  name: string | null;
  avatar_url: string | null;
  role: UserRole;
  is_verified: boolean;
  created_at: string;
  updated_at: string;
}

export interface Maker {
  id: string;
  profile_id: string;
  slug: string;
  name: string;
  tagline: string | null;
  bio: string | null;
  location: string | null;
  since: number | null;
  rating: number;
  products_count: number;
  image_url: string | null;
  featured: boolean;
  is_verified: boolean;
  created_at: string;
  updated_at: string;
  // Joined data
  products?: Product[];
}

export interface Category {
  id: string;
  name: string;
  description: string | null;
  image_url: string | null;
  sort_order: number;
  product_count: number;
  created_at: string;
}

export interface ProductVariant {
  label: string;
  price: number;
}

export interface Product {
  id: string;
  maker_id: string;
  slug: string;
  name: string;
  category_id: string;
  price: number;
  rating: number;
  reviews_count: number;
  image_url: string | null;
  images: string[];
  description: string | null;
  materials: string[];
  variants: ProductVariant[];
  badge: 'bestseller' | 'popular' | 'most_reviewed' | null;
  is_active: boolean;
  stock_count: number;
  created_at: string;
  updated_at: string;
  // Joined data
  maker?: Maker;
  category?: Category;
}

export interface Review {
  id: string;
  product_id: string;
  user_id: string | null;
  author_name: string;
  rating: number;
  text: string | null;
  verified: boolean;
  created_at: string;
  // Joined data
  product?: Product;
  user?: Profile;
}

export interface CartItem {
  id: string;
  user_id: string;
  product_id: string;
  variant_label: string | null;
  quantity: number;
  created_at: string;
  updated_at: string;
  // Joined data
  product?: Product;
}

export interface ShippingAddress {
  name: string;
  email: string;
  address: string;
  city: string;
  state?: string;
  zip: string;
  country: string;
}

export type OrderStatus = 'pending' | 'processing' | 'shipped' | 'delivered' | 'cancelled';

export interface Order {
  id: string;
  order_number: string;
  user_id: string | null;
  status: OrderStatus;
  subtotal: number;
  shipping: number;
  total: number;
  shipping_address: ShippingAddress;
  metadata: Record<string, unknown>;
  created_at: string;
  updated_at: string;
  // Joined data
  items?: OrderItem[];
  user?: Profile;
}

export interface OrderItem {
  id: string;
  order_id: string;
  product_id: string | null;
  maker_id: string | null;
  product_name: string;
  maker_name: string;
  price: number;
  variant_label: string | null;
  quantity: number;
  // Joined data
  product?: Product;
  maker?: Maker;
}

// API Request/Response Types

export interface ProductFilters {
  category?: string;
  minPrice?: number;
  maxPrice?: number;
  maker?: string;
  featured?: boolean;
  search?: string;
}

export type ProductSort = 'featured' | 'price-low' | 'price-high' | 'rating' | 'reviews' | 'newest';

export interface ProductListParams {
  filters?: ProductFilters;
  sort?: ProductSort;
  page?: number;
  limit?: number;
}

export interface CartItemInput {
  product_id: string;
  variant_label?: string | null;
  quantity: number;
}

export interface CreateOrderInput {
  shipping_address: ShippingAddress;
  shipping_cost?: number;
}

export interface CreateReviewInput {
  product_id: string;
  rating: number;
  text: string;
}

export interface CreateMakerInput {
  slug: string;
  name: string;
  tagline?: string;
  bio?: string;
  location?: string;
  since?: number;
  image_url?: string;
}

export interface CreateProductInput {
  slug: string;
  name: string;
  category_id: string;
  price: number;
  image_url?: string;
  images?: string[];
  description?: string;
  materials?: string[];
  variants?: ProductVariant[];
  badge?: 'bestseller' | 'popular' | 'most_reviewed';
  stock_count?: number;
}

export interface UpdateProductInput extends Partial<CreateProductInput> {
  is_active?: boolean;
}
