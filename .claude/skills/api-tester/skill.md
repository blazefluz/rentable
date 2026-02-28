# API Tester & Debugger

Test and debug the Rentable REST API endpoints with proper authentication and multi-tenancy context.

## Description

This skill provides comprehensive API testing capabilities:
- Testing all REST endpoints with proper authentication
- Generating and managing JWT tokens
- Testing multi-tenant isolation
- Debugging API responses
- Load testing and performance monitoring
- Validating data integrity
- Testing webhook integrations (Stripe)

## When to Use

Use this skill when you need to:
- Test API endpoints before frontend integration
- Debug authentication issues
- Verify multi-tenant data isolation
- Test payment workflows
- Validate booking availability logic
- Generate test data for development
- Performance test the API

## Authentication Setup

### Generate JWT Token
```ruby
# Get or create test user
company = Company.find_by(subdomain: "acme")

ActsAsTenant.with_tenant(company) do
  user = User.find_by(email: "admin@test.com")

  unless user
    user = User.create!(
      name: "Test Admin",
      email: "admin@test.com",
      password: "password123",
      password_confirmation: "password123",
      role: :admin,
      company: company
    )
  end

  # Generate JWT token
  token = user.generate_jwt

  puts "JWT Token:"
  puts token
  puts ""
  puts "Use in curl commands:"
  puts "curl -H 'Authorization: Bearer #{token}' ..."
end
```

### Test Authentication
```bash
# Test token validity
curl http://localhost:4000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"

# Expected: Returns user details
```

## API Testing Commands

### Test Product Endpoints
```bash
# List all products
curl http://localhost:4000/api/v1/products \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get specific product
curl http://localhost:4000/api/v1/products/44 \
  -H "Authorization: Bearer YOUR_TOKEN"

# Create product
curl -X POST http://localhost:4000/api/v1/products \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "product": {
      "name": "Test Camera",
      "daily_price_cents": 10000,
      "daily_price_currency": "USD",
      "quantity": 5,
      "active": true
    }
  }'

# Check availability
curl "http://localhost:4000/api/v1/products/44/availability?start_date=2026-03-10&end_date=2026-03-12" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Test Booking Endpoints
```bash
# List bookings
curl http://localhost:4000/api/v1/bookings \
  -H "Authorization: Bearer YOUR_TOKEN"

# Get booking details
curl http://localhost:4000/api/v1/bookings/29 \
  -H "Authorization: Bearer YOUR_TOKEN"

# Create booking
curl -X POST http://localhost:4000/api/v1/bookings \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "booking": {
      "customer_name": "Test Customer",
      "customer_email": "test@example.com",
      "start_date": "2026-03-15",
      "end_date": "2026-03-17",
      "booking_line_items_attributes": [
        {
          "bookable_type": "Product",
          "bookable_id": 44,
          "quantity": 1,
          "days": 2
        }
      ]
    }
  }'

# Check availability
curl "http://localhost:4000/api/v1/bookings/check_availability?start_date=2026-03-15&end_date=2026-03-17" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      {"product_id": 44, "quantity": 2},
      {"product_id": 45, "quantity": 1}
    ]
  }'

# Confirm booking
curl -X PATCH http://localhost:4000/api/v1/bookings/29/confirm \
  -H "Authorization: Bearer YOUR_TOKEN"

# Cancel booking
curl -X PATCH http://localhost:4000/api/v1/bookings/29/cancel \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"reason": "Customer requested"}'
```

### Test Payment Endpoints
```bash
# Create payment intent
curl -X POST http://localhost:4000/api/v1/payments/stripe/create_intent \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "booking_id": 29,
    "amount": 20800
  }'

# Test webhook (local testing)
curl -X POST http://localhost:4000/api/v1/payments/stripe/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "type": "payment_intent.succeeded",
    "data": {
      "object": {
        "id": "pi_test_123",
        "metadata": {
          "booking_id": "29"
        }
      }
    }
  }'
```

## Testing Multi-Tenancy

### Verify Data Isolation
```ruby
# Create two companies
company1 = Company.create!(
  name: "Company A",
  subdomain: "company-a",
  business_email: "admin@companya.com",
  status: :active
)

company2 = Company.create!(
  name: "Company B",
  subdomain: "company-b",
  business_email: "admin@companyb.com",
  status: :active
)

# Create products in each company
ActsAsTenant.with_tenant(company1) do
  Product.create!(
    name: "Company A Product",
    daily_price_cents: 10000,
    quantity: 5
  )
end

ActsAsTenant.with_tenant(company2) do
  Product.create!(
    name: "Company B Product",
    daily_price_cents: 15000,
    quantity: 3
  )
end

# Verify isolation
ActsAsTenant.with_tenant(company1) do
  puts "Company A sees: #{Product.count} products"
  puts Product.pluck(:name)
end

ActsAsTenant.with_tenant(company2) do
  puts "Company B sees: #{Product.count} products"
  puts Product.pluck(:name)
end

# Should see different products in each company
```

### Test Cross-Tenant Access Prevention
```ruby
# Try to access Company A's product from Company B's context
company1 = Company.find_by(subdomain: "company-a")
company2 = Company.find_by(subdomain: "company-b")

product_id = nil
ActsAsTenant.with_tenant(company1) do
  product_id = Product.first.id
end

ActsAsTenant.with_tenant(company2) do
  begin
    Product.find(product_id)
    puts "❌ SECURITY BREACH: Cross-tenant access allowed!"
  rescue ActiveRecord::RecordNotFound
    puts "✅ Security working: Cross-tenant access prevented"
  end
end
```

## Debugging Helpers

### Inspect API Response
```ruby
# Pretty print API response structure
ActsAsTenant.with_tenant(company) do
  booking = Booking.find(29)

  puts "Booking API Response Structure:"
  puts "=" * 60

  response = {
    id: booking.id,
    reference_number: booking.reference_number,
    customer_name: booking.customer_name,
    start_date: booking.start_date,
    end_date: booking.end_date,
    status: booking.status,
    subtotal: booking.subtotal&.format,
    tax_total: booking.tax_total&.format,
    grand_total: booking.grand_total&.format,
    line_items: booking.booking_line_items.map { |item|
      {
        product: item.bookable&.name,
        quantity: item.quantity,
        days: item.days,
        price: item.price.format,
        subtotal: item.line_subtotal.format,
        tax: item.tax_amount&.format || "$0.00",
        total_with_tax: item.line_total_with_tax.format
      }
    }
  }

  puts JSON.pretty_generate(response)
end
```

### Debug Money Calculations
```ruby
# Verify all money calculations are correct
ActsAsTenant.with_tenant(company) do
  booking = Booking.find(29)

  puts "Money Calculation Debug:"
  puts "=" * 60

  booking.booking_line_items.each do |item|
    puts "Item: #{item.bookable.name}"
    puts "  Price cents: #{item.price_cents}"
    puts "  Price formatted: #{item.price.format}"
    puts "  Quantity: #{item.quantity}"
    puts "  Days: #{item.days}"
    puts "  Calculation: #{item.price_cents} × #{item.quantity} × #{item.days} = #{item.price_cents * item.quantity * item.days} cents"
    puts "  Line subtotal cents: #{item.line_subtotal.cents}"
    puts "  Line subtotal formatted: #{item.line_subtotal.format}"
    puts "  Match: #{item.line_subtotal.cents == (item.price_cents * item.quantity * item.days) ? '✅' : '❌'}"
    puts ""
  end
end
```

### Test Availability Logic
```ruby
# Comprehensive availability test
ActsAsTenant.with_tenant(company) do
  product = Product.find(44)

  puts "Availability Logic Test for: #{product.name}"
  puts "=" * 60

  # Test 1: Check total inventory
  puts "Total inventory: #{product.quantity}"
  puts "Available quantity (no dates): #{product.available_quantity}"

  # Test 2: Check specific dates
  start_date = Date.parse("2026-03-15")
  end_date = Date.parse("2026-03-17")

  available = product.available_quantity(start_date, end_date)
  puts "Available for #{start_date} to #{end_date}: #{available}"

  # Test 3: Find conflicting bookings
  conflicts = BookingLineItem.joins(:booking)
    .where(bookable: product)
    .where.not(bookings: { status: [:cancelled, :completed] })
    .where("bookings.start_date <= ? AND bookings.end_date >= ?", end_date, start_date)

  puts "Conflicting bookings: #{conflicts.count}"
  conflicts.each do |item|
    puts "  Booking #{item.booking.reference_number}: #{item.quantity} units from #{item.booking.start_date} to #{item.booking.end_date}"
  end

  # Test 4: Day-by-day breakdown
  puts ""
  puts "Day-by-day availability:"
  (start_date..end_date).each do |date|
    qty = product.available_quantity(date, date)
    puts "  #{date}: #{qty} available"
  end
end
```

## Performance Testing

### Load Test API Endpoints
```ruby
require 'benchmark'

ActsAsTenant.with_tenant(company) do
  puts "Performance Test: Product Listing"
  puts "=" * 60

  # Test 1: List products
  time = Benchmark.realtime do
    100.times { Product.all.to_a }
  end
  puts "100 product listings: #{(time * 1000).round(2)}ms (#{(time / 100 * 1000).round(2)}ms avg)"

  # Test 2: Availability check
  product = Product.first
  time = Benchmark.realtime do
    100.times do
      product.available_quantity(7.days.from_now, 10.days.from_now)
    end
  end
  puts "100 availability checks: #{(time * 1000).round(2)}ms (#{(time / 100 * 1000).round(2)}ms avg)"

  # Test 3: Booking creation
  time = Benchmark.realtime do
    10.times do |i|
      Booking.create!(
        customer_name: "Test #{i}",
        customer_email: "test#{i}@example.com",
        start_date: (i + 5).days.from_now,
        end_date: (i + 7).days.from_now,
        status: :draft
      )
    end
  end
  puts "10 booking creations: #{(time * 1000).round(2)}ms (#{(time / 10 * 1000).round(2)}ms avg)"

  # Cleanup
  Booking.where("customer_email LIKE ?", "test%@example.com").destroy_all
end
```

## Common Test Scenarios

### Scenario 1: Complete Booking Flow Test
```bash
#!/bin/bash
TOKEN="your_jwt_token"
BASE_URL="http://localhost:4000/api/v1"

echo "1. Create booking..."
BOOKING_ID=$(curl -s -X POST "$BASE_URL/bookings" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "booking": {
      "customer_name": "Test Customer",
      "customer_email": "test@example.com",
      "start_date": "2026-03-20",
      "end_date": "2026-03-22",
      "booking_line_items_attributes": [
        {"bookable_type": "Product", "bookable_id": 44, "quantity": 1}
      ]
    }
  }' | jq -r '.booking.id')

echo "Booking created: ID $BOOKING_ID"

echo "2. Confirm booking..."
curl -s -X PATCH "$BASE_URL/bookings/$BOOKING_ID/confirm" \
  -H "Authorization: Bearer $TOKEN"

echo "3. Create payment intent..."
curl -s -X POST "$BASE_URL/payments/stripe/create_intent" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"booking_id\": $BOOKING_ID}"

echo "Test complete!"
```

### Scenario 2: Test Data Validation
```ruby
ActsAsTenant.with_tenant(company) do
  puts "Data Validation Test"
  puts "=" * 60

  # Test invalid booking
  booking = Booking.new(
    customer_name: "",  # Invalid: required
    start_date: Date.today,
    end_date: Date.yesterday  # Invalid: end before start
  )

  if booking.valid?
    puts "❌ Validation failed: Invalid booking passed validation"
  else
    puts "✅ Validation working:"
    booking.errors.full_messages.each { |msg| puts "  - #{msg}" }
  end
end
```

## Troubleshooting

**401 Unauthorized**: Token expired or invalid - generate new JWT
**404 Not Found**: Resource doesn't exist in current tenant scope
**422 Unprocessable**: Validation failed - check error messages
**500 Server Error**: Check Rails logs for stack trace
**CORS errors**: Verify CORS configuration in Rails

## Related Skills
- rental-equipment-manager
- booking-workflow-manager
- multi-tenancy-manager
- database-reporter
