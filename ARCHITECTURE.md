# Floggers Backend Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT (Next.js)                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐│
│  │   Browser   │  │   Cart      │  │   Auth State        ││
│  │   React     │  │   Context   │  │   (Supabase Auth)   ││
│  └──────┬──────┘  └──────┬──────┘  └──────────┬────────────┘│
└─────────┼────────────────┼────────────────────┼─────────────┘
          │                │                    │
          │   Supabase JS  │                    │
          │   Client SDK   │                    │
          ▼                ▼                    ▼
┌─────────────────────────────────────────────────────────────┐
│                     SUPABASE PLATFORM                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Auth      │  │   Database  │  │   Storage           │  │
│  │   (OAuth)   │  │  (PostgreSQL)│  │   (Images)          │  │
│  │             │  │             │  │                     │  │
│  │  • Google   │  │  • Products │  │  • products/          │  │
│  │  • Apple    │  │  • Makers   │  │  • makers/           │  │
│  │  • Facebook │  │  • Orders   │  │  • avatars/          │  │
│  │  • Phone    │  │  • Reviews  │  │                     │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│                         │                                    │
│                  ┌──────┴──────┐                            │
│                  │   Realtime  │                            │
│                  │   (WebSockets)│                           │
│                  └─────────────┘                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ SQL / REST API
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      DATABASE (PostgreSQL)                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   profiles  │  │   makers    │  │   categories        │  │
│  │   (users)   │  │   (sellers) │  │   (product types)   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   products  │  │   reviews   │  │   cart_items        │  │
│  │   (listings)│  │   (ratings) │  │   (shopping cart)   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
│  ┌─────────────┐  ┌─────────────┐                           │
│  │   orders    │  │ order_items │                           │
│  │   (purchases)│  │  (line items)│                          │
│  └─────────────┘  └─────────────┘                           │
└─────────────────────────────────────────────────────────────┘
```

## Authentication Flow

```
User clicks "Sign in with Google"
         │
         ▼
┌──────────────────┐
│  Google OAuth     │
│  Consent Screen   │
└────────┬───────────┘
         │
         ▼
Redirect to callback URL
         │
         ▼
┌──────────────────┐
│  Supabase Auth    │
│  Creates:         │
│  • auth.users     │
│  • public.profiles│
└────────┬──────────┘
         │
         ▼
Redirect to /dashboard
         │
         ▼
User is authenticated!
JWT stored in cookies
```

## Data Flow Examples

### Product Browsing
```
User visits /category
         │
         ▼
┌────────────────────────┐
│ getProducts({           │
│   filters, sort, page   │
│ })                      │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Supabase Query:        │
│ SELECT * FROM products │
│ WHERE is_active = true │
│ ORDER BY rating DESC   │
│ LIMIT 20 OFFSET 0      │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Response: Product[]    │
│ with maker & category  │
│ joined data            │
└────────────────────────┘
```

### Adding to Cart
```
User clicks "Add to Cart"
         │
         ▼
┌────────────────────────┐
│ addToCart({            │
│   product_id,          │
│   variant,             │
│   quantity             │
│ })                     │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ UPSERT cart_items      │
│ ON CONFLICT UPDATE     │
│ quantity               │
└────────┬───────────────┘
         │
         ▼
Cart updated in real-time
(via Supabase Realtime)
```

### Checkout Flow
```
User proceeds to checkout
         │
         ▼
┌────────────────────────┐
│ Submit shipping info   │
│ & create order         │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ RPC: create_order_     │
│ from_cart()            │
│ • Calculate totals     │
│ • Create order record  │
│ • Copy cart to items   │
│ • Clear cart           │
└────────┬───────────────┘
         │
         ▼
┌────────────────────────┐
│ Redirect to payment     │
│ (Stripe integration)   │
└────────────────────────┘
```

## Security Model

### Row Level Security (RLS)

Every table has RLS policies:

```
┌────────────────────────────────────────────────────────────┐
│                    TABLE ACCESS RULES                       │
├────────────────────────────────────────────────────────────┤
│ profiles    │ SELECT: all │ INSERT: own │ UPDATE: own       │
│ makers      │ SELECT: all │ INSERT: own │ UPDATE: own       │
│ products    │ SELECT: all │ INSERT: maker │ UPDATE: maker  │
│ reviews     │ SELECT: all │ INSERT: auth │ UPDATE: own     │
│ cart_items  │ SELECT: own │ INSERT: own │ UPDATE: own      │
│ orders      │ SELECT: own/maker │ INSERT: own           │
└────────────────────────────────────────────────────────────┘
```

### Authentication Levels

```
Public (no auth)
    │
    ├── Can view: products, makers, categories, reviews
    │
    ▼
Authenticated (customer)
    │
    ├── Can: create reviews, manage cart, create orders
    │
    ▼
Maker role
    │
    ├── Can: create/update products, view maker orders
    │
    ▼
Admin role
    │
    └── Can: manage all data, verify makers
```

## Database Relationships

```
auth.users ────────► profiles (1:1)
                         │
                         ▼
                    makers (1:1, optional)
                         │
                         ▼
                    products (1:many)
                         │
              ┌──────────┼──────────┐
              ▼          ▼          ▼
         reviews    cart_items   order_items
              │          │          │
              └──────────┴──────────┘
                         │
                    orders (many:1 with users)
```

## API Pattern

### Client-Side Usage
```typescript
// Read data (public)
const { data: products } = await supabase
  .from('products')
  .select('*, maker:makers(*)')
  .eq('is_active', true);

// Write data (authenticated)
const { data } = await supabase
  .from('cart_items')
  .upsert({ user_id, product_id, quantity })
  .select();
```

### Server-Side Usage
```typescript
// Service role for admin tasks
const serviceClient = createClient(url, serviceRoleKey);

const { data } = await serviceClient
  .from('orders')
  .select('*');
```

## Key Design Decisions

1. **Supabase over custom API**: Reduces backend code, built-in auth & realtime
2. **RLS for security**: Database-level permissions instead of API middleware
3. **Triggers for consistency**: Auto-update ratings, counts, timestamps
4. **UUIDs for IDs**: No sequential IDs exposed in URLs
5. **JSONB for arrays**: Materials, images, variants stored as JSON
6. **Soft deletes**: `is_active` flag instead of hard deletes
7. **Order denormalization**: Product/maker names copied to order_items for history
