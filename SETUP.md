# Floggers Backend Setup Guide

This guide walks you through setting up the Floggers backend with Supabase and Google OAuth.

## Prerequisites

- Node.js 18+
- Supabase CLI installed
- Google Cloud account
- Supabase account (free tier works)

---

## Step 1: Create Supabase Project

### Option A: Via Dashboard (Recommended)

1. Go to [supabase.com](https://supabase.com)
2. Sign up/login
3. Click "New Project"
4. Choose your organization
5. Project name: `floggers`
6. Database password: Generate a secure one
7. Region: Choose closest to your users
8. Click "Create new project"

Wait ~2 minutes for the database to provision.

### Option B: Via CLI

```bash
# Login
supabase login

# Initialize project
supabase init

# Link to your remote project
supabase link --project-ref your-project-ref
```

---

## Step 2: Get Your Credentials

1. In Supabase Dashboard, go to **Project Settings** → **API**
2. Copy these values:
   - `URL` → `NEXT_PUBLIC_SUPABASE_URL`
   - `anon public` → `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `service_role secret` → `SUPABASE_SERVICE_ROLE_KEY` (keep this secret!)

3. Create `.env.local` file:

```bash
cp .env.example .env.local
```

4. Fill in the values in `.env.local`

---

## Step 3: Run Database Migrations

### Option A: Via SQL Editor (Easiest)

1. Go to Supabase Dashboard → **SQL Editor**
2. Create a new query
3. Copy contents of `supabase/migrations/001_initial_schema.sql`
4. Run the query
5. Repeat for `002_functions_triggers.sql`
6. Repeat for `003_seed_data.sql`

### Option B: Via CLI

```bash
# Make sure you're linked to your project
supabase link --project-ref your-project-ref

# Push migrations
supabase db push
```

---

## Step 4: Set Up Google OAuth

### 4.1 Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click project dropdown → **New Project**
3. Project name: `Floggers Auth`
4. Click **Create**

### 4.2 Enable APIs

1. Go to **APIs & Services** → **Library**
2. Search for "Google+ API" or "People API"
3. Click **Enable**

### 4.3 Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Choose **External** (for testing)
3. Click **Create**
4. Fill in:
   - App name: `Floggers`
   - User support email: your email
   - Developer contact information: your email
5. Click **Save and Continue**
6. On Scopes, click **Add or Remove Scopes**
7. Select:
   - `openid`
   - `/auth/userinfo.email`
   - `/auth/userinfo.profile`
8. Click **Save and Continue**
9. On Test users, add your email
10. Click **Save and Continue**
11. Click **Back to Dashboard**

### 4.4 Create OAuth Credentials

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth 2.0 Client ID**
3. Application type: **Web application**
4. Name: `Floggers Web`
5. Authorized JavaScript origins:
   ```
   http://localhost:3000
   https://your-app.com
   ```
6. Authorized redirect URIs:
   ```
   http://localhost:54321/auth/v1/callback
   https://your-project-ref.supabase.co/auth/v1/callback
   ```
7. Click **Create**
8. Copy:
   - Client ID → `GOOGLE_CLIENT_ID`
   - Client secret → `GOOGLE_CLIENT_SECRET`

### 4.5 Configure Supabase Auth

1. Go to Supabase Dashboard → **Authentication** → **Providers**
2. Find **Google** and click **Settings** (gear icon)
3. Enable the provider
4. Paste in your Google Client ID and Secret
5. Click **Save**

---

## Step 5: Set Up Storage Buckets

1. Go to Supabase Dashboard → **Storage**
2. Click **New bucket**
3. Create three buckets:
   - `products` (public)
   - `makers` (public)
   - `avatars` (public)

4. For each bucket, set policies. Go to each bucket → **Policies**

For `products` bucket:
```sql
-- Allow public to view images
CREATE POLICY "Products public read"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'products');

-- Allow authenticated users to upload
CREATE POLICY "Authenticated upload"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'products' 
    AND auth.role() = 'authenticated'
  );

-- Allow authenticated users to delete their own files
CREATE POLICY "Authenticated delete"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'products' 
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
```

Repeat similar policies for `makers` and `avatars` buckets.

---

## Step 6: Install & Run

```bash
# Install dependencies
npm install

# Install Supabase client library
npm install @supabase/supabase-js @supabase/auth-helpers-nextjs

# Run the dev server
npm run dev
```

---

## Step 7: Test the Setup

### Test Google OAuth

1. Go to `http://localhost:3000/login`
2. Click "Sign in with Google"
3. Complete Google OAuth flow
4. Should redirect to `/dashboard`
5. Check Supabase Dashboard → **Table Editor** → `profiles` - your user should appear

### Test Database

1. Go to Supabase Dashboard → **Table Editor**
2. Check `categories` table - should have 6 categories
3. Check `profiles` - should have your user

---

## Troubleshooting

### "Invalid redirect URI" error

Make sure the redirect URI in Google Cloud Console matches exactly:
```
https://your-project-ref.supabase.co/auth/v1/callback
```

### "User not created" in profiles

The `handle_new_user` trigger should auto-create profiles. If not:
1. Go to Supabase Dashboard → **Database** → **Functions**
2. Check if `handle_new_user` function exists
3. Check if trigger `trg_create_profile_on_signup` is attached to `auth.users`

### Images won't upload

Check storage bucket policies. Make sure:
1. Buckets are public
2. Policies allow authenticated users to upload
3. File size limits are reasonable (default is 50MB)

---

## Next Steps

1. ✅ Backend is ready!
2. ⬜ Integrate with frontend
3. ⬜ Add product images
4. ⬜ Set up Stripe payments
5. ⬜ Configure email notifications

---

## Useful Links

- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [Google OAuth Setup](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Storage Policies](https://supabase.com/docs/guides/storage/security/access-control)
- [RLS Guide](https://supabase.com/docs/guides/auth/row-level-security)
