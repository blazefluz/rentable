# Rental Equipment Manager

Manages products, kits, inventory, and availability for the Rentable equipment rental system.

## Description

This skill helps you manage the complete lifecycle of rental equipment including:
- Creating and updating products with proper pricing (daily, weekly, monthly)
- Managing product inventory and availability
- Creating equipment kits (bundles of products)
- Checking availability across date ranges
- Managing product instances (serialized items)
- Handling product variants (size, color, model)
- Setting up product collections and categories

## When to Use

Use this skill when you need to:
- Add new rental equipment to inventory
- Update product pricing or details
- Check if equipment is available for booking
- Create equipment packages/kits
- Track individual serialized items
- Manage product variants
- Generate inventory reports

## Key Concepts

### Product Types
- **Regular Products**: Standard rental items (cameras, lenses, lights)
- **Kits**: Bundled products sold together
- **Product Instances**: Individual serialized items with unique serial numbers
- **Product Variants**: Different variations (size, color, storage capacity)

### Pricing Structure
- Daily price (base rate)
- Weekly price (discounted for 7+ days)
- Monthly price (discounted for 30+ days)
- Weekend pricing (optional higher rate)
- Dynamic pricing rules based on demand

### Availability Logic
- Products track total quantity
- Bookings reduce available quantity for date ranges
- Same-day turnaround allowed (end date of booking A = start date of booking B)
- Kit availability requires ALL components to be available

## Commands

### Create a Product
```ruby
# Within tenant context
ActsAsTenant.with_tenant(company) do
  product = Product.create!(
    name: "Canon EOS R5 Camera Body",
    description: "Professional full-frame mirrorless camera",
    sku: "CANON-R5-001",
    barcode: "CAM-R5-001",
    daily_price_cents: 15000,  # $150/day
    daily_price_currency: "USD",
    weekly_price_cents: 80000,  # $800/week
    monthly_price_cents: 250000, # $2500/month
    quantity: 5,
    available_quantity: 5,
    category: "Cameras",
    manufacturer: "Canon",
    model_number: "EOS R5",
    tags: ["camera", "full-frame", "mirrorless"],
    active: true,
    bookable: true
  )
end
```

### Check Availability
```ruby
# Check if product is available for date range
product = Product.find(id)
start_date = Date.parse("2026-03-01")
end_date = Date.parse("2026-03-05")

availability = product.available_quantity(start_date, end_date)
puts "Available quantity: #{availability}"

# Get detailed availability breakdown
breakdown = product.availability_breakdown(start_date, end_date)
# Returns availability by date
```

### Create a Kit
```ruby
ActsAsTenant.with_tenant(company) do
  kit = Kit.create!(
    name: "Wedding Photography Package",
    description: "Complete kit for wedding photography",
    daily_price_cents: 50000,
    active: true
  )

  # Add products to kit
  camera = Product.find_by(sku: "CANON-R5-001")
  lens = Product.find_by(sku: "CANON-RF-2470")

  kit.kit_items.create!(product: camera, quantity: 2)
  kit.kit_items.create!(product: lens, quantity: 1)
end
```

### Create Product Instance (Serialized Item)
```ruby
ActsAsTenant.with_tenant(company) do
  product = Product.find_by(sku: "CANON-R5-001")

  instance = product.product_instances.create!(
    serial_number: "CAM-R5-12345",
    asset_tag: "ASSET-001",
    condition: :excellent,
    status: :available,
    purchase_date: 1.year.ago,
    purchase_price_cents: 400000,
    purchase_price_currency: "USD"
  )
end
```

### Generate Inventory Report
```ruby
ActsAsTenant.with_tenant(company) do
  puts "=== INVENTORY REPORT ==="
  puts ""

  Product.group(:category).count.each do |category, count|
    puts "#{category}: #{count} products"

    Product.where(category: category).each do |p|
      puts "  • #{p.name}"
      puts "    Quantity: #{p.quantity}"
      puts "    Daily Price: #{p.daily_price.format}"
      puts "    Status: #{p.active? ? 'Active' : 'Inactive'}"
    end
    puts ""
  end

  total_value = Product.sum(:daily_price_cents)
  puts "Total Daily Inventory Value: $#{total_value / 100.0}"
end
```

## API Endpoints

```bash
# List all products
GET /api/v1/products

# Get product details
GET /api/v1/products/:id

# Create product
POST /api/v1/products

# Update product
PATCH /api/v1/products/:id

# Check availability
GET /api/v1/products/:id/availability?start_date=2026-03-01&end_date=2026-03-05

# List kits
GET /api/v1/kits

# Get kit availability
GET /api/v1/kits/:id/availability?start_date=2026-03-01&end_date=2026-03-05
```

## Best Practices

1. **Always use tenant context**: Wrap operations in `ActsAsTenant.with_tenant(company)`
2. **Validate availability**: Check availability before confirming bookings
3. **Use Money objects**: Prices are stored as cents, use Money for formatting
4. **Track instances**: Use ProductInstance for high-value serialized items
5. **Set proper categories**: Helps with searching and filtering
6. **Use tags**: Enable flexible searching and grouping
7. **Weekend pricing**: Set higher rates for weekend rentals if applicable

## Common Scenarios

### Scenario 1: Adding Camera Equipment
```ruby
company = Company.find_by(subdomain: "acme")

ActsAsTenant.with_tenant(company) do
  # Create camera
  camera = Product.create!(
    name: "Sony A7 IV Camera",
    daily_price_cents: 12000,
    daily_price_currency: "USD",
    quantity: 3,
    category: "Cameras",
    manufacturer: "Sony",
    active: true
  )

  # Create lens
  lens = Product.create!(
    name: "Sony FE 24-70mm f/2.8",
    daily_price_cents: 8000,
    daily_price_currency: "USD",
    quantity: 5,
    category: "Lenses",
    active: true
  )

  # Create bundle kit
  kit = Kit.create!(
    name: "Sony A7 IV Complete Kit",
    daily_price_cents: 18000,
    active: true
  )

  kit.kit_items.create!([
    { product: camera, quantity: 1 },
    { product: lens, quantity: 1 }
  ])
end
```

### Scenario 2: Checking Multi-Day Availability
```ruby
product = Product.find(44)

# Check availability for specific dates
start_date = Date.parse("2026-03-10")
end_date = Date.parse("2026-03-15")

# Get available quantity
available = product.available_quantity(start_date, end_date)

if available >= 2
  puts "✓ 2 units available for booking"
else
  puts "✗ Only #{available} units available"
end

# Get day-by-day breakdown
breakdown = product.availability_breakdown(start_date, end_date)
breakdown.each do |date, qty|
  puts "#{date}: #{qty} available"
end
```

## Troubleshooting

**Product not showing in API**: Check `active` flag and company scoping
**Availability incorrect**: Ensure bookings are in correct status (confirmed/paid)
**Kit unavailable**: Check if ALL component products are available
**Price showing wrong**: Verify currency and use Money#format for display

## Related Skills
- booking-workflow-manager
- multi-tenancy-manager
- api-tester