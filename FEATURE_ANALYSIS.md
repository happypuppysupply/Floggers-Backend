# Complete Frontend Feature Analysis

## All Pages & Routes

### Public Pages
| Route | Feature | Data Needed |
|-------|---------|-------------|
| `/` | Home - hero, featured floggers, categories, featured makers, CTA | products (featured), categories, makers (featured) |
| `/category` | Product browse with search, filter, sort | products, categories |
| `/category/[slug]` | Category detail page | products by category |
| `/product/[id]` | Product detail - gallery, variants, add to cart, reviews, related | product, reviews, related products |
| `/makers` | List all makers | makers |
| `/maker/[id]` | Maker storefront - profile + their products | maker, products by maker |
| `/cart` | Shopping cart (localStorage) | cart items |
| `/checkout` | Checkout flow - shipping, payment, success | cart, order creation |
| `/sell` | "Why Sell" landing page for makers | static content |
| `/login` | Sign in with email/password + OAuth (Google/Apple/Facebook/Phone) | auth |
| `/signup` | Create account with email/password + OAuth | auth |
| `/forgot-password` | Password reset | auth |

### Maker Dashboard (Protected)
| Route | Feature | Data Needed |
|-------|---------|-------------|
| `/dashboard` | Overview - stats cards, recent orders, top products | orders, products, stats |
| `/dashboard/products` | Product list - search, filter, edit modal, delete | products CRUD |
| `/dashboard/products/new` | Add new product form | product creation |
| `/dashboard/orders` | Order list - search, filter, detail modal | orders |
| `/dashboard/messages` | Chat/messaging with buyers | conversations, messages |
| `/dashboard/wallet` | Balance, payouts, connect bank/card/stripe | wallet, payouts |
| `/dashboard/customers` | Customer list with order history | customers |
| `/dashboard/analytics` | Revenue, orders, visitors, conversion charts | analytics data |
| `/dashboard/import` | Import from Etsy/Shopify/CSV | external integrations |
| `/dashboard/settings` | Shop settings - name, tagline, email, location, bio | maker profile update |

### Maker Onboarding
| Route | Feature | Data Needed |
|-------|---------|-------------|
| `/maker/signup` | 3-step application form (shop info, craft, personal) | maker application |

## Data Entities

### Users
- OAuth providers: Google, Apple, Facebook, Phone
- Email/password auth
- Roles: customer, maker, admin
- Profile: name, email, avatar

### Products
- Name, slug, category, price
- Variants (label + price)
- Images (gallery)
- Description, materials
- Badge (bestseller, popular, most_reviewed)
- Stock count, status (active, low_stock, out_of_stock)
- Rating, reviews_count
- Maker reference

### Makers
- Profile link
- Shop name, slug, tagline, bio
- Location, since year
- Rating, products_count
- Image/avatar
- Featured flag, verified flag
- Application status

### Categories
- ID, name, description, image
- Product count

### Reviews
- Product reference
- User reference (or anonymous)
- Rating (1-5), text
- Verified purchase flag
- Date

### Cart
- localStorage for guests
- DB sync for authenticated users
- Product, variant, quantity

### Orders
- Order number (FL-XXXXX)
- User reference
- Status: pending, processing, shipped, fulfilled, cancelled
- Items (denormalized: product name, maker name, price, qty)
- Shipping address
- Payment method
- Subtotal, shipping, total
- Date

### Messages (Chat)
- Conversations between buyer and seller
- Messages with sender, text, time, read status
- Real-time messaging

### Wallet/Payouts
- Balance (available, pending, lifetime)
- Payout methods: bank (ACH), debit card, Stripe Connect
- Payout history
- Fee structure (8% transaction fee)

### Customers
- Aggregated view per customer
- Total orders, total spent, last order date

### Analytics
- Revenue over time
- Order counts
- Visitor stats
- Conversion rates
- Product performance

### Import
- Etsy API integration
- Shopify API integration
- CSV upload
- Product mapping/draft mode
