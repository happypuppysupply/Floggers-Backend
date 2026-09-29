# Floggers Backend

BDSM Marketplace backend built with Supabase (PostgreSQL + Auth + Realtime + Storage).

## Quick Start

### 1. Create Supabase Project

```bash
# Install Supabase CLI if you haven't
npm install -g supabase

# Login to Supabase
supabase login

# Create a new project (or use existing)
# Go to https://supabase.com/dashboard and create a new project
```

### 2. Configure Environment Variables

```bash
# Copy the example env file
cp .env.example .env.local

# Fill in your Supabase credentials from the dashboard
# Project Settings → API
```

### 3. Run Migrations

```bash
# Link your project
supabase link --project-ref your-project-ref

# Push migrations to Supabase
supabase db push

# Or apply SQL files manually in Supabase Dashboard → SQL Editor
```

### 4. Set Up Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project
3. Enable **Google+ API** (or People API)
4. Go to **Credentials** → **Create Credentials** → **OAuth 2.0 Client ID**
5. Configure OAuth consent screen:
   - App name: "Floggers"
   - User support email: your email
   - Scopes: `openid`, `email`, `profile`
6. Add authorized redirect URIs:
   - `https://your-project.supabase.co/auth/v1/callback`
   - `http://localhost:54321/auth/v1/callback` (for local dev)

7. In Supabase Dashboard → Authentication → Providers → Google:
   - Enable Google provider
   - Paste Client ID and Secret

### 5. Set Up Storage Buckets

In Supabase Dashboard → Storage:

1. Create bucket `products` (public)
2. Create bucket `makers` (public)
3. Create bucket `avatars` (public)

Add policies:

```sql
-- Products bucket: public read, authenticated write
CREATE POLICY "Products public read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'products');

CREATE POLICY "Authenticated upload to products"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'products' AND auth.role() = 'authenticated');

-- Makers bucket
CREATE POLICY "Makers public read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'makers');

CREATE POLICY "Authenticated upload to makers"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'makers' AND auth.role() = 'authenticated');
```

### 6. Install Dependencies & Run

```bash
npm install
npm run dev
```

## Project Structure

```
floggers-backend/
├── supabase/
│   ├── migrations/
│   │   ├── 001_initial_schema.sql    # Core tables
│   │   ├── 002_functions_triggers.sql # Auto-updates, ratings
│   │   └── 003_seed_data.sql         # Categories, sample data
│   └── config.toml                   # Supabase local config
├── src/
│   ├── lib/
│   │   └── supabase.ts               # Client + API functions
│   ├── types/
│   │   └── index.ts                  # TypeScript types
│   └── api/                          # API routes (if needed)
├── .env.example
├── package.json
└── README.md
```

## Database Schema

### Tables

| Table | Description |
|-------|-------------|
| `profiles` | Extended user profiles |
| `makers` | Artisan/seller profiles |
| `categories` | Product categories |
| `products` | Product listings |
| `reviews` | Product reviews |
| `cart_items` | User shopping carts |
| `orders` | Order records |
| `order_items` | Line items in orders |

### Key Features

- **Row Level Security (RLS)**: Every table has RLS policies
- **Auto-updating triggers**: `updated_at`, product ratings, maker counts
- **Full-text search**: Built-in product search
- **Order generation**: `create_order_from_cart()` function

## API Usage

```typescript
import { 
  getProducts, 
  getProductBySlug, 
  getMakers,
  signInWithGoogle,
  getCartItems,
  addToCart
} from '@/lib/supabase';

// List products
const { products, count } = await getProducts({
  filters: { category: 'floggers' },
  sort: 'rating',
  limit: 20
});

// Get single product
const product = await getProductBySlug('the-sovereign-flogger');

// Google OAuth
await signInWithGoogle();

// Cart operations
const cartItems = await getCartItems();
await addToCart({
  product_id: 'uuid',
  variant_label: 'Standard',
  quantity: 1
});
```

## Auth Flow

1. User clicks "Sign in with Google"
2. `signInWithGoogle()` redirects to Google
3. Google redirects to `/auth/callback`
4. Supabase exchanges code for session
5. Trigger creates `profiles` row automatically
6. User is redirected to dashboard

## Environment Variables

| Variable | Description |
|----------|-------------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Public API key |
| `SUPABASE_SERVICE_ROLE_KEY` | Server-only key (keep secret!) |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID |
| `GOOGLE_CLIENT_SECRET` | Google OAuth secret |

## Commands

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server |
| `npm run db:migrate` | Push migrations to Supabase |
| `npm run db:reset` | Reset local database |
| `supabase status` | Check local Supabase status |
| `supabase stop` | Stop local Supabase |

## Next Steps

1. ✅ Database schema with RLS
2. ✅ Google OAuth configured
3. ✅ API client functions
4. ⬜ Integrate with frontend
5. ⬜ Add image upload UI
6. ⬜ Real-time cart sync
7. ⬜ Stripe payments
8. ⬜ Email notifications

## Resources

- [Supabase Docs](https://supabase.com/docs)
- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Google OAuth Setup](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
