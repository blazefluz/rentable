# Booking Workflow Manager

Manages the complete booking lifecycle including creation, confirmation, payment, and fulfillment for equipment rentals.

## Description

This skill handles all aspects of the booking workflow:
- Creating and managing bookings
- Checking availability and preventing clashes
- Processing payments via Stripe
- Managing booking status transitions
- Handling cancellations and refunds
- Calculating pricing with taxes and discounts
- Generating quotes/estimates
- Managing recurring bookings

## When to Use

Use this skill when you need to:
- Create a new equipment rental booking
- Check if dates are available
- Process booking payments
- Confirm or cancel bookings
- Generate rental quotes
- Handle overdue returns
- Process cancellations and refunds
- Create recurring/repeat bookings

## Booking Lifecycle

```
draft → pending → confirmed → paid → in_progress → completed
                      ↓
                  cancelled
```

### Status Definitions
- **draft**: Initial creation, not confirmed
- **pending**: Awaiting payment or approval
- **confirmed**: Approved, awaiting payment
- **paid**: Payment received, ready for fulfillment
- **in_progress**: Equipment out with customer
- **completed**: Equipment returned, booking closed
- **cancelled**: Booking cancelled

## Commands

### Create a Basic Booking
```ruby
company = Company.find_by(subdomain: "acme")

ActsAsTenant.with_tenant(company) do
  # Create booking
  booking = Booking.create!(
    customer_name: "John Smith",
    customer_email: "john@example.com",
    customer_phone: "+1 555-0100",
    start_date: 3.days.from_now,
    end_date: 5.days.from_now,
    status: :draft,
    client: Client.find_by(email: "john@example.com"),
    manager: User.find_by(role: :admin)
  )

  # Add products to booking
  camera = Product.find_by(sku: "CANON-R5-001")
  lens = Product.find_by(sku: "CANON-RF-2470")

  booking.booking_line_items.create!([
    {
      bookable: camera,
      quantity: 2,
      days: 2,
      price_cents: camera.daily_price_cents,
      price_currency: "USD"
    },
    {
      bookable: lens,
      quantity: 1,
      days: 2,
      price_cents: lens.daily_price_cents,
      price_currency: "USD"
    }
  ])

  # Calculate totals
  booking.calculate_total_price
  booking.save!

  puts "Booking created: #{booking.reference_number}"
  puts "Total: #{booking.grand_total.format}"
end
```

### Check Availability Before Booking
```ruby
ActsAsTenant.with_tenant(company) do
  start_date = Date.parse("2026-03-10")
  end_date = Date.parse("2026-03-12")

  product_ids = [44, 45, 46]
  quantities = [2, 1, 1]

  available = Booking.check_availability(
    start_date: start_date,
    end_date: end_date,
    items: product_ids.zip(quantities).map { |id, qty|
      { product_id: id, quantity: qty }
    }
  )

  if available[:all_available]
    puts "✓ All items available for booking"
  else
    puts "✗ Some items unavailable:"
    available[:unavailable_items].each do |item|
      puts "  • Product #{item[:product_id]}: need #{item[:requested]}, only #{item[:available]} available"
    end
  end
end
```

### Process Payment with Stripe
```ruby
ActsAsTenant.with_tenant(company) do
  booking = Booking.find_by(reference_number: "BK20260226820B8670")

  # Create payment intent
  payment_intent = Stripe::PaymentIntent.create({
    amount: booking.grand_total.cents,
    currency: booking.grand_total.currency.iso_code.downcase,
    metadata: {
      booking_id: booking.id,
      booking_reference: booking.reference_number,
      company_id: company.id
    }
  })

  # Save payment intent ID
  booking.update!(stripe_payment_intent_id: payment_intent.id)

  puts "Payment intent created: #{payment_intent.client_secret}"
end
```

### Confirm a Booking
```ruby
ActsAsTenant.with_tenant(company) do
  booking = Booking.find(id)

  # Verify availability first
  if booking.available?
    booking.confirm!
    puts "Booking confirmed: #{booking.reference_number}"
    puts "Status: #{booking.status}"
  else
    puts "Cannot confirm - items not available"
  end
end
```

### Handle Booking Cancellation
```ruby
ActsAsTenant.with_tenant(company) do
  booking = Booking.find(id)
  user = User.find(user_id)

  # Calculate refund based on cancellation policy
  refund_info = booking.calculate_cancellation_refund

  puts "Cancellation Refund Info:"
  puts "  Refund amount: #{refund_info[:refund_cents] / 100.0}"
  puts "  Cancellation fee: #{refund_info[:fee_cents] / 100.0}"
  puts "  Refund percentage: #{refund_info[:refund_percentage]}%"

  # Process cancellation
  if booking.cancel_booking!(
    user: user,
    reason: "Customer requested cancellation"
  )
    puts "Booking cancelled successfully"
    puts "Refund status: #{booking.refund_status}"
  end
end
```

### Create Quote/Estimate
```ruby
ActsAsTenant.with_tenant(company) do
  # Create booking as quote
  booking = Booking.create!(
    customer_name: "Potential Client",
    customer_email: "client@example.com",
    start_date: 7.days.from_now,
    end_date: 10.days.from_now,
    status: :draft
  )

  # Add items
  booking.booking_line_items.create!(
    bookable: Product.find(44),
    quantity: 1,
    days: 3,
    price_cents: Product.find(44).daily_price_cents,
    price_currency: "USD"
  )

  # Convert to quote
  booking.convert_to_quote!(expires_in: 7.days)

  puts "Quote created: #{booking.quote_number}"
  puts "Expires: #{booking.quote_expires_at}"
  puts "Total: #{booking.grand_total.format}"
end
```

### Handle Overdue Returns
```ruby
ActsAsTenant.with_tenant(company) do
  # Find overdue bookings
  overdue = Booking.where("end_date < ? AND status = ?", Date.today, :in_progress)

  overdue.each do |booking|
    days_overdue = (Date.today - booking.end_date).to_i

    booking.booking_line_items.each do |item|
      # Calculate late fees
      late_fee = item.calculate_late_fees

      puts "Overdue Booking: #{booking.reference_number}"
      puts "  Customer: #{booking.customer_name}"
      puts "  Days overdue: #{days_overdue}"
      puts "  Late fee: #{late_fee.format}"
    end
  end
end
```

### Create Recurring Booking
```ruby
ActsAsTenant.with_tenant(company) do
  # Create recurring booking template
  recurring = RecurringBooking.create!(
    name: "Monthly Equipment Rental - ABC Corp",
    frequency: :monthly,
    start_date: Date.today,
    end_date: 1.year.from_now,
    client: Client.find_by(name: "ABC Corp"),
    booking_template: {
      customer_name: "ABC Corp",
      customer_email: "rentals@abc.com",
      items: [
        { product_id: 44, quantity: 2 },
        { product_id: 45, quantity: 1 }
      ]
    },
    active: true
  )

  # Generate next occurrence
  next_booking = recurring.generate_next_booking!

  puts "Recurring booking created"
  puts "Next occurrence: #{next_booking.reference_number}"
end
```

## API Endpoints

```bash
# List bookings
GET /api/v1/bookings

# Get booking details
GET /api/v1/bookings/:id

# Create booking
POST /api/v1/bookings

# Update booking
PATCH /api/v1/bookings/:id

# Check availability
GET /api/v1/bookings/check_availability?start_date=2026-03-01&end_date=2026-03-05

# Confirm booking
PATCH /api/v1/bookings/:id/confirm

# Cancel booking
PATCH /api/v1/bookings/:id/cancel

# Complete booking
PATCH /api/v1/bookings/:id/complete

# Convert to quote
POST /api/v1/bookings/:id/convert_to_quote

# Approve quote
POST /api/v1/bookings/:id/approve_quote
```

## Pricing Calculation

### Simple Pricing
```ruby
# Daily rate × quantity × days
price = daily_price_cents * quantity * days
```

### Dynamic Pricing (with weekend rates)
```ruby
# Weekend days use weekend_price_cents
# Weekday days use daily_price_cents
weekend_days = date_range.count { |d| d.saturday? || d.sunday? }
weekday_days = total_days - weekend_days

price = (weekend_days * weekend_price_cents) + (weekday_days * daily_price_cents)
price = price * quantity
```

### Tax Calculation
```ruby
# Subtotal is calculated first
subtotal = line_items.sum(&:line_total)

# Apply tax rate (if set)
tax_rate = booking.default_tax_rate
tax_amount = subtotal * (tax_rate.rate / 100.0)

# Grand total
grand_total = subtotal + tax_amount
```

## Cancellation Policies

### Flexible
- Full refund if cancelled 24+ hours before start
- 50% refund if cancelled within 24 hours

### Moderate
- Full refund if cancelled 5+ days before start
- 50% refund if cancelled 2-5 days before
- No refund if cancelled within 48 hours

### Strict
- Full refund if cancelled 14+ days before start
- 50% refund if cancelled 7-14 days before
- No refund if cancelled within 7 days

### No Refund
- No refunds for any cancellation

## Best Practices

1. **Always check availability**: Before confirming bookings
2. **Use reference numbers**: For customer communication
3. **Calculate totals**: Call `calculate_total_price` after changes
4. **Handle payments async**: Use webhooks for payment confirmation
5. **Set cancellation policies**: Define clear refund rules
6. **Track status changes**: Maintain audit trail
7. **Send notifications**: Email customers on status changes

## Common Scenarios

### Scenario 1: Complete Booking Flow
```ruby
ActsAsTenant.with_tenant(company) do
  # 1. Create draft booking
  booking = Booking.create!(
    customer_name: "John Doe",
    customer_email: "john@example.com",
    start_date: 3.days.from_now,
    end_date: 5.days.from_now,
    status: :draft
  )

  # 2. Add items
  booking.booking_line_items.create!(
    bookable: Product.find(44),
    quantity: 1,
    days: 2,
    price_cents: 15000
  )

  # 3. Calculate totals
  booking.calculate_total_price
  booking.save!

  # 4. Confirm booking
  booking.confirm!

  # 5. Process payment (Stripe webhook handles this)
  # When payment succeeds, booking.status = :paid

  # 6. Mark as in progress (when equipment picked up)
  booking.update!(status: :in_progress)

  # 7. Complete booking (when equipment returned)
  booking.complete!
end
```

### Scenario 2: Handle Partial Availability
```ruby
ActsAsTenant.with_tenant(company) do
  start_date = 5.days.from_now
  end_date = 7.days.from_now

  product = Product.find(44)
  requested_qty = 5

  available = product.available_quantity(start_date, end_date)

  if available < requested_qty
    puts "Only #{available} of #{requested_qty} available"
    puts "Options:"
    puts "  1. Reduce quantity to #{available}"
    puts "  2. Choose different dates"
    puts "  3. Split into multiple bookings"
  end
end
```

## Troubleshooting

**Booking total incorrect**: Ensure `calculate_total_price` was called
**Cannot confirm booking**: Check availability and booking status
**Payment not processing**: Verify Stripe credentials and webhook setup
**Tax not calculating**: Ensure tax rates are set up and assigned
**Cancellation refund wrong**: Check cancellation policy settings

## Related Skills
- rental-equipment-manager
- stripe-payment-handler
- multi-tenancy-manager
- database-reporter
