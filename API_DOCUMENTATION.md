# Rentable API Documentation

**Base URL:** `http://localhost:3000/api/v1`
**Version:** 1.0
**Format:** JSON

---

## 🚀 Quick Start

All endpoints return JSON and support standard HTTP methods (GET, POST, PATCH, DELETE).

### Currency Support
- USD (US Dollar) - Default
- EUR (Euro)
- GBP (British Pound)

---

## 📦 Products API

### List All Products
```http
GET /api/v1/products
```

**Query Parameters:**
- `query` (optional) - Search by name or description
- `category` (optional) - Filter by category
- `min_price` (optional) - Minimum daily price (in dollars, e.g., 50.00)
- `max_price` (optional) - Maximum daily price (in dollars, e.g., 200.00)
- `min_quantity` (optional) - Minimum available quantity
- `include_inactive` (optional) - Include inactive products (true/false, default: false)
- `sort_by` (optional) - Sort by field: name, price, quantity, category, created_at (default: created_at)
- `sort_order` (optional) - Sort order: asc, desc (default: desc)
- `page` (optional) - Page number (default: 1)
- `per_page` (optional) - Items per page (default: 25)

**Response:**
```json
{
  "products": [
    {
      "id": 1,
      "name": "Canon EOS R5",
      "description": "45MP full-frame mirrorless camera",
      "category": "Camera",
      "daily_price": {
        "amount": 1500000,
        "currency": "NGN",
        "formatted": "₦15,000.00"
      },
      "quantity": 3,
      "active": true,
      "barcode": "CAM-R5-001",
      "created_at": "2026-02-25T08:30:00.000Z",
      "updated_at": "2026-02-25T08:30:00.000Z"
    }
  ],
  "meta": {
    "current_page": 1,
    "next_page": null,
    "prev_page": null,
    "total_pages": 1,
    "total_count": 6
  }
}
```

### Get Single Product
```http
GET /api/v1/products/:id
```

**Response:**
```json
{
  "product": {
    "id": 1,
    "name": "Canon EOS R5",
    "description": "45MP full-frame mirrorless camera",
    "category": "Camera",
    "daily_price": {
      "amount": 1500000,
      "currency": "NGN",
      "formatted": "₦15,000.00"
    },
    "quantity": 3,
    "active": true,
    "barcode": "CAM-R5-001",
    "serial_numbers": ["SN001", "SN002"],
    "images": [],
    "created_at": "2026-02-25T08:30:00.000Z",
    "updated_at": "2026-02-25T08:30:00.000Z"
  }
}
```

### Create Product
```http
POST /api/v1/products
```

**Request Body:**
```json
{
  "product": {
    "name": "Sony A7 IV",
    "description": "33MP full-frame camera",
    "category": "Camera",
    "daily_price_cents": 1200000,
    "daily_price_currency": "NGN",
    "quantity": 5,
    "barcode": "CAM-A7IV-001",
    "serial_numbers": ["SN100", "SN101"],
    "active": true
  }
}
```

**Response:**
```json
{
  "product": { ... },
  "message": "Product created successfully"
}
```

### Update Product
```http
PATCH /api/v1/products/:id
```

**Request Body:** (same as create, all fields optional)

### Delete Product (Archive)
```http
DELETE /api/v1/products/:id
```

**Response:**
```json
{
  "message": "Product archived successfully"
}
```

### Check Product Availability
```http
GET /api/v1/products/:id/availability?start_date=2026-03-01&end_date=2026-03-05
```

**Query Parameters:**
- `start_date` (required) - Format: YYYY-MM-DD
- `end_date` (required) - Format: YYYY-MM-DD

**Response:**
```json
{
  "product_id": 1,
  "product_name": "Canon EOS R5",
  "total_quantity": 3,
  "available_quantity": 2,
  "is_available": true,
  "date_range": {
    "start": "2026-03-01",
    "end": "2026-03-05"
  },
  "availability_by_date": {
    "2026-03-01": {
      "total": 3,
      "booked": 1,
      "available": 2
    },
    "2026-03-02": {
      "total": 3,
      "booked": 1,
      "available": 2
    }
  }
}
```

### Attach Images to Product
```http
POST /api/v1/products/:id/attach_images
Content-Type: multipart/form-data
```

**Request Body:**
- `images[]` (required) - Array of image files

**Example using curl:**
```bash
curl -X POST http://localhost:3000/api/v1/products/1/attach_images \
  -F "images[]=@/path/to/image1.jpg" \
  -F "images[]=@/path/to/image2.jpg"
```

**Response:**
```json
{
  "message": "Images attached successfully",
  "images": [
    {
      "id": 1,
      "url": "http://localhost:3000/rails/active_storage/blobs/..."
    },
    {
      "id": 2,
      "url": "http://localhost:3000/rails/active_storage/blobs/..."
    }
  ]
}
```

### Remove Image from Product
```http
DELETE /api/v1/products/:id/remove_image/:image_id
```

**Response:**
```json
{
  "message": "Image removed successfully"
}
```

---

## 📦 Kits API

### List All Kits
```http
GET /api/v1/kits
```

**Response:**
```json
{
  "kits": [
    {
      "id": 1,
      "name": "Beginner Video Kit",
      "description": "Everything you need to start",
      "daily_price": {
        "amount": 1800000,
        "currency": "NGN",
        "formatted": "₦18,000.00"
      },
      "active": true,
      "items_count": 4,
      "created_at": "2026-02-25T08:30:00.000Z",
      "updated_at": "2026-02-25T08:30:00.000Z"
    }
  ],
  "meta": { ... }
}
```

### Get Single Kit
```http
GET /api/v1/kits/:id
```

**Response:**
```json
{
  "kit": {
    "id": 1,
    "name": "Beginner Video Kit",
    "description": "Everything you need to start",
    "daily_price": {
      "amount": 1800000,
      "currency": "NGN",
      "formatted": "₦18,000.00"
    },
    "active": true,
    "items_count": 4,
    "items": [
      {
        "id": 1,
        "product": {
          "id": 2,
          "name": "Sony A7 III",
          "category": "Camera"
        },
        "quantity": 1
      },
      {
        "id": 2,
        "product": {
          "id": 3,
          "name": "Canon RF 24-70mm",
          "category": "Lens"
        },
        "quantity": 1
      }
    ],
    "images": [],
    "created_at": "2026-02-25T08:30:00.000Z",
    "updated_at": "2026-02-25T08:30:00.000Z"
  }
}
```

### Create Kit
```http
POST /api/v1/kits
```

**Request Body:**
```json
{
  "kit": {
    "name": "Pro Cinema Kit",
    "description": "Complete professional setup",
    "daily_price_cents": 3500000,
    "daily_price_currency": "NGN",
    "active": true
  },
  "kit_items": [
    {
      "product_id": 1,
      "quantity": 1
    },
    {
      "product_id": 3,
      "quantity": 1
    }
  ]
}
```

### Update Kit
```http
PATCH /api/v1/kits/:id
```

### Delete Kit (Archive)
```http
DELETE /api/v1/kits/:id
```

### Check Kit Availability
```http
GET /api/v1/kits/:id/availability?start_date=2026-03-01&end_date=2026-03-05&quantity=1
```

**Response:**
```json
{
  "kit_id": 1,
  "kit_name": "Beginner Video Kit",
  "requested_quantity": 1,
  "available_quantity": 3,
  "is_available": true,
  "date_range": {
    "start": "2026-03-01",
    "end": "2026-03-05"
  },
  "component_availability": [
    {
      "product_id": 2,
      "product_name": "Sony A7 III",
      "required_quantity": 1,
      "available_quantity": 5
    }
  ]
}
```

### Attach Images to Kit
```http
POST /api/v1/kits/:id/attach_images
Content-Type: multipart/form-data
```

**Request Body:**
- `images[]` (required) - Array of image files

**Response:**
```json
{
  "message": "Images attached successfully",
  "images": [
    {
      "id": 1,
      "url": "http://localhost:3000/rails/active_storage/blobs/..."
    }
  ]
}
```

### Remove Image from Kit
```http
DELETE /api/v1/kits/:id/remove_image/:image_id
```

**Response:**
```json
{
  "message": "Image removed successfully"
}
```

---

## 📅 Bookings API

### List All Bookings
```http
GET /api/v1/bookings
```

**Query Parameters:**
- `status` (optional) - Filter by status: draft, pending, confirmed, paid, cancelled, completed
- `page` (optional)
- `per_page` (optional)

**Response:**
```json
{
  "bookings": [
    {
      "id": 1,
      "reference_number": "BK20260225AB12CD34",
      "start_date": "2026-02-28T00:00:00.000Z",
      "end_date": "2026-03-02T00:00:00.000Z",
      "rental_days": 3,
      "customer": {
        "name": "Adebayo Johnson",
        "email": "adebayo@example.com",
        "phone": "+234 803 123 4567"
      },
      "status": "confirmed",
      "total_price": {
        "amount": 4500000,
        "currency": "NGN",
        "formatted": "₦45,000.00"
      },
      "items_count": 2,
      "created_at": "2026-02-25T08:30:00.000Z",
      "updated_at": "2026-02-25T08:30:00.000Z"
    }
  ],
  "meta": { ... }
}
```

### Get Single Booking
```http
GET /api/v1/bookings/:id
```

**Response:**
```json
{
  "booking": {
    "id": 1,
    "reference_number": "BK20260225AB12CD34",
    "start_date": "2026-02-28T00:00:00.000Z",
    "end_date": "2026-03-02T00:00:00.000Z",
    "rental_days": 3,
    "customer": {
      "name": "Adebayo Johnson",
      "email": "adebayo@example.com",
      "phone": "+234 803 123 4567"
    },
    "status": "confirmed",
    "total_price": {
      "amount": 4500000,
      "currency": "NGN",
      "formatted": "₦45,000.00"
    },
    "items_count": 2,
    "notes": "Wedding shoot in Lekki",
    "line_items": [
      {
        "id": 1,
        "bookable_type": "Product",
        "bookable_id": 1,
        "bookable_name": "Canon EOS R5",
        "quantity": 1,
        "days": 3,
        "price_per_day": {
          "amount": 1500000,
          "currency": "NGN",
          "formatted": "₦15,000.00"
        },
        "line_total": {
          "amount": 4500000,
          "currency": "NGN",
          "formatted": "₦45,000.00"
        }
      }
    ],
    "created_at": "2026-02-25T08:30:00.000Z",
    "updated_at": "2026-02-25T08:30:00.000Z"
  }
}
```

### Create Booking
```http
POST /api/v1/bookings
```

**Request Body:**
```json
{
  "booking": {
    "start_date": "2026-03-10T00:00:00.000Z",
    "end_date": "2026-03-15T00:00:00.000Z",
    "customer_name": "Chioma Nwosu",
    "customer_email": "chioma@example.com",
    "customer_phone": "+234 810 555 7890",
    "status": "draft",
    "notes": "Corporate event"
  },
  "line_items": [
    {
      "bookable_type": "Product",
      "bookable_id": 1,
      "quantity": 2
    },
    {
      "bookable_type": "Kit",
      "bookable_id": 1,
      "quantity": 1
    }
  ]
}
```

**Response:**
```json
{
  "booking": { ... },
  "message": "Booking created successfully"
}
```

### Update Booking
```http
PATCH /api/v1/bookings/:id
```

### Delete Booking
```http
DELETE /api/v1/bookings/:id
```

### Confirm Booking
```http
PATCH /api/v1/bookings/:id/confirm
```

**Response:**
```json
{
  "booking": { ... },
  "message": "Booking confirmed"
}
```

### Cancel Booking
```http
PATCH /api/v1/bookings/:id/cancel
```

### Complete Booking
```http
PATCH /api/v1/bookings/:id/complete
```

### Check Availability for Booking
```http
GET /api/v1/bookings/check_availability
```

**Query Parameters:**
```
?start_date=2026-03-10&end_date=2026-03-15&items[0][bookable_type]=Product&items[0][bookable_id]=1&items[0][quantity]=2
```

**Response:**
```json
{
  "date_range": {
    "start": "2026-03-10",
    "end": "2026-03-15"
  },
  "all_available": true,
  "items": [
    {
      "bookable_type": "Product",
      "bookable_id": 1,
      "bookable_name": "Canon EOS R5",
      "requested_quantity": 2,
      "available_quantity": 3,
      "is_available": true
    }
  ]
}
```

---

## 📊 Booking Statuses

- **draft** (0) - Initial state
- **pending** (1) - Awaiting confirmation
- **confirmed** (2) - Confirmed by admin
- **paid** (3) - Payment received
- **cancelled** (4) - Cancelled
- **completed** (5) - Booking fulfilled

---

## 🔧 Error Responses

### 404 Not Found
```json
{
  "error": "Product not found"
}
```

### 422 Unprocessable Entity
```json
{
  "errors": [
    "Name can't be blank",
    "Quantity must be greater than 0"
  ]
}
```

### 400 Bad Request
```json
{
  "error": "Invalid date format"
}
```

---

## 🧪 Testing with cURL

### Get all products
```bash
curl http://localhost:3000/api/v1/products
```

### Check product availability
```bash
curl "http://localhost:3000/api/v1/products/1/availability?start_date=2026-03-01&end_date=2026-03-05"
```

### Create a booking
```bash
curl -X POST http://localhost:3000/api/v1/bookings \
  -H "Content-Type: application/json" \
  -d '{
    "booking": {
      "start_date": "2026-03-10T00:00:00.000Z",
      "end_date": "2026-03-15T00:00:00.000Z",
      "customer_name": "Test User",
      "customer_email": "test@example.com",
      "status": "draft"
    },
    "line_items": [
      {
        "bookable_type": "Product",
        "bookable_id": 1,
        "quantity": 1
      }
    ]
  }'
```

---

## 🌐 CORS Configuration

CORS is enabled for all origins (`*`) in development. Update `config/initializers/cors.rb` for production.

---

## 💡 Next Steps

1. **Authentication** - Add JWT/API tokens
2. **Rate Limiting** - Implement rate limiting
3. **Webhooks** - Payment webhooks (Paystack/Stripe)
4. **Filtering** - Advanced filtering & sorting
5. **File Uploads** - Image upload endpoints

---

**Need help?** Check the source code or raise an issue!

---

## 🔐 Authentication API

### Register New User
```http
POST /api/v1/auth/register
```

**Request:**
```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "password_confirmation": "password123",
    "name": "John Doe"
  }
}
```

**Response:**
```json
{
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "John Doe",
    "role": "customer",
    "api_token": "abc123...",
    "created_at": "2026-02-25T09:00:00.000Z"
  },
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "message": "Registration successful"
}
```

### Login
```http
POST /api/v1/auth/login
```

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "user": { ... },
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "message": "Login successful"
}
```

### Get Current User
```http
GET /api/v1/auth/me
Authorization: Bearer YOUR_JWT_TOKEN
```

### Refresh Token
```http
POST /api/v1/auth/refresh
Authorization: Bearer YOUR_JWT_TOKEN
```

---

## 💳 Payment API (Stripe)

### Create Payment Intent
```http
POST /api/v1/payments/stripe/create_intent
Authorization: Bearer YOUR_JWT_TOKEN
```

**Request:**
```json
{
  "booking_id": 1
}
```

**Response:**
```json
{
  "client_secret": "pi_xxx_secret_yyy",
  "payment_intent_id": "pi_xxx",
  "amount": 15000,
  "currency": "usd",
  "status": "requires_payment_method"
}
```

### Stripe Webhook (Automatic)
```http
POST /api/v1/payments/stripe/webhook
```

**Events Handled:**
- `payment_intent.succeeded` - Marks booking as paid
- `payment_intent.payment_failed` - Adds failure note
- `payment_intent.canceled` - Cancels booking

---

## 🔒 Protected Endpoints

Add authentication to requests:
```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:3000/api/v1/auth/me
```

### User Roles
- **customer** (0) - Default role
- **staff** (1) - Can manage bookings
- **admin** (2) - Full access

---

## 💰 Currency Support

**Default:** USD (US Dollar)
**Supported:** USD, EUR, GBP

All prices are in cents (e.g., $150.00 = 15000 cents)

---

## 🌐 Stripe Integration Guide

### 1. Get Stripe Keys
1. Sign up at https://stripe.com
2. Get API keys from https://dashboard.stripe.com/apikeys
3. Add to `.env`:
   ```
   STRIPE_PUBLISHABLE_KEY=pk_test_...
   STRIPE_SECRET_KEY=sk_test_...
   ```

### 2. Test Payment Flow

**Backend (Create Intent):**
```bash
curl -X POST http://localhost:3000/api/v1/payments/stripe/create_intent \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"booking_id": 1}'
```

**Frontend (Stripe.js):**
```javascript
// Use the client_secret with Stripe.js
const stripe = Stripe('pk_test_...');
const {error} = await stripe.confirmCardPayment(clientSecret, {
  payment_method: {
    card: cardElement,
    billing_details: {name: 'John Doe'}
  }
});
```

### 3. Setup Webhook
1. Install Stripe CLI: https://stripe.com/docs/stripe-cli
2. Forward events to local:
   ```bash
   stripe listen --forward-to localhost:3000/api/v1/payments/stripe/webhook
   ```
3. Get webhook secret and add to `.env`:
   ```
   STRIPE_WEBHOOK_SECRET=whsec_...
   ```

### Test Cards
```
Success: 4242 4242 4242 4242
Decline: 4000 0000 0000 0002
3D Secure: 4000 0025 0000 3155
```

---

## 📧 Email Notifications

The system automatically sends email notifications for key booking events:

### Booking Confirmation Email
Sent when a booking is confirmed via `PATCH /api/v1/bookings/:id/confirm`

**Includes:**
- Booking reference number
- Rental period (start and end dates)
- List of items with quantities and prices
- Total price
- Payment instructions

### Payment Success Email
Sent automatically when Stripe webhook receives `payment_intent.succeeded` event

**Includes:**
- Payment confirmation badge
- Booking reference number
- Rental period
- Items booked
- Amount paid
- Next steps (pickup instructions, return reminders)

### Email Configuration

Configure SMTP settings in `.env`:

```bash
# Gmail (Development)
SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_gmail_app_password
SMTP_DOMAIN=gmail.com
FROM_EMAIL=bookings@rentable.app

# SendGrid (Production recommended)
SMTP_ADDRESS=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USERNAME=apikey
SMTP_PASSWORD=your_sendgrid_api_key
```

**Gmail Setup:**
1. Enable 2-Factor Authentication
2. Create App Password at https://myaccount.google.com/apppasswords
3. Use the 16-character password in `SMTP_PASSWORD`

**Email Templates:**
- HTML and plain text versions provided
- Responsive design optimized for mobile
- Located in `app/views/booking_mailer/`

---

## 📝 Complete Flow Example

### 1. Register User
```bash
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "password": "password123",
      "password_confirmation": "password123",
      "name": "Test User"
    }
  }'
```

### 2. Create Booking
```bash
curl -X POST http://localhost:3000/api/v1/bookings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "booking": {
      "start_date": "2026-03-10",
      "end_date": "2026-03-15",
      "customer_name": "Test User",
      "customer_email": "test@example.com"
    },
    "line_items": [
      {
        "bookable_type": "Product",
        "bookable_id": 1,
        "quantity": 1
      }
    ]
  }'
```

### 3. Create Payment
```bash
curl -X POST http://localhost:3000/api/v1/payments/stripe/create_intent \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"booking_id": 1}'
```

### 4. Complete Payment (Frontend)
Use Stripe.js with the `client_secret` from step 3

---

## ⚡ Quick Deploy

### Environment Variables
```bash
cp .env.example .env
# Edit .env with your credentials
```

### Database Setup
```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

### Start Server
```bash
bin/rails server
```

---

**API is ready for production! 🚀**
