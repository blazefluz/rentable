# 🎬 Rentable - Equipment Rental SaaS API

A complete, production-ready REST API for equipment rental/booking (cameras, tools, AV gear, etc.) with sophisticated availability management, Stripe payments, and JWT authentication.

**Inspired by:** [AdamRMS](https://github.com/adam-rms/adam-rms) concepts  
**Built with:** Rails 8, PostgreSQL, Stripe, JWT

---

## ✨ Features

### Core Functionality
- ✅ **Equipment Management** - Products, Kits (bundles), Categories
- ✅ **Sophisticated Availability** - Prevent booking clashes with quantity tracking
- ✅ **Multi-Currency Support** - USD (default), EUR, GBP
- ✅ **Booking System** - Full lifecycle (draft → pending → confirmed → paid → completed)
- ✅ **Polymorphic Line Items** - Book individual products or complete kits

### Business Logic (AdamRMS-Inspired)
- ✅ **Clash Prevention** - Smart overlap detection for date ranges
- ✅ **Quantity Management** - Support products with qty > 1
- ✅ **Same-Day Turnaround** - End of booking A = Start of booking B (no conflict)
- ✅ **Kit Availability** - Check ALL components before allowing kit booking
- ✅ **Daily Breakdown** - See availability by date

### Technical
- ✅ **JWT Authentication** - Secure API access with roles (customer, staff, admin)
- ✅ **Stripe Integration** - Payment Intents + Webhooks
- ✅ **RESTful API** - Clean, consistent JSON endpoints
- ✅ **CORS Enabled** - Ready for frontend integration
- ✅ **Pagination** - Kaminari-powered
- ✅ **Error Handling** - Proper HTTP status codes

---

## 🚀 Quick Start

### Prerequisites
- Ruby 3.4.2
- PostgreSQL
- Stripe Account (test mode)

### Installation

```bash
# Install dependencies
bundle install

# Setup environment
cp .env.example .env
# Edit .env with your credentials

# Setup database
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed

# Start server
bin/rails server
```

Visit: **http://localhost:3000**

---

## 📚 API Documentation

Full documentation: **[API_DOCUMENTATION.md](API_DOCUMENTATION.md)**

### Quick Examples

**Register User:**
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "user@example.com",
      "password": "password123",
      "password_confirmation": "password123",
      "name": "John Doe"
    }
  }'
```

**List Products:**
```bash
curl http://localhost:3000/api/v1/products
```

**Check Availability:**
```bash
curl "http://localhost:3000/api/v1/products/1/availability?start_date=2026-03-01&end_date=2026-03-05"
```

---

## 💳 Stripe Integration

### Setup

1. Get Stripe keys: https://dashboard.stripe.com/apikeys
2. Add to `.env`:
   ```
   STRIPE_PUBLISHABLE_KEY=pk_test_...
   STRIPE_SECRET_KEY=sk_test_...
   ```

### Test Cards
- Success: `4242 4242 4242 4242`
- Decline: `4000 0000 0000 0002`

---

## 🏗️ Architecture

### API Endpoints

```
Authentication
POST   /api/v1/auth/register
POST   /api/v1/auth/login
GET    /api/v1/auth/me
POST   /api/v1/auth/refresh

Products
GET    /api/v1/products
GET    /api/v1/products/:id
POST   /api/v1/products
PATCH  /api/v1/products/:id
DELETE /api/v1/products/:id
GET    /api/v1/products/:id/availability

Kits
GET    /api/v1/kits
GET    /api/v1/kits/:id
POST   /api/v1/kits
PATCH  /api/v1/kits/:id
DELETE /api/v1/kits/:id
GET    /api/v1/kits/:id/availability

Bookings
GET    /api/v1/bookings
GET    /api/v1/bookings/:id
POST   /api/v1/bookings
PATCH  /api/v1/bookings/:id
DELETE /api/v1/bookings/:id
GET    /api/v1/bookings/check_availability
PATCH  /api/v1/bookings/:id/confirm
PATCH  /api/v1/bookings/:id/cancel
PATCH  /api/v1/bookings/:id/complete

Payments (Stripe)
POST   /api/v1/payments/stripe/create_intent
POST   /api/v1/payments/stripe/webhook
```

---

## 🧪 Testing

```bash
# Sample data
bin/rails db:seed

# Test availability
bin/rails runner '
  camera = Product.first
  puts "Available: #{camera.available_quantity(3.days.from_now, 5.days.from_now)}"
'
```

---

## 🚢 Deployment

### Railway.app / Render

1. Connect GitHub repo
2. Add environment variables (see .env.example)
3. Deploy!

---

## 🛠️ Tech Stack

- Rails 8.1.2
- PostgreSQL
- Stripe
- JWT
- money-rails
- Kaminari

---

**Built with ❤️ for the global rental industry**
