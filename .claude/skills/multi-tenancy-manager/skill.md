# Multi-Tenancy Manager

Manage companies, subscriptions, and tenant isolation in the Rentable SaaS platform.

## Description

This skill handles all aspects of multi-tenancy:
- Company signup and onboarding
- Subdomain management
- Subscription tier management
- Feature gates and limits
- Data isolation verification
- Cross-tenant security testing
- Company settings and branding
- User-company relationships

## When to Use

Use this skill when you need to:
- Create new rental companies (tenants)
- Manage company subscriptions
- Configure company settings and branding
- Verify data isolation between companies
- Test cross-tenant access prevention
- Manage subscription upgrades/downgrades
- Set feature flags per company
- Assign users to companies

## Subscription Tiers

### Free Tier
- Max 1 user
- Max 10 products
- Basic features only
- No API access
- No multi-location
- Community support

### Starter ($29/month)
- Max 5 users
- Max 100 products
- Basic features + reporting
- API access (limited)
- Single location
- Email support

### Professional ($99/month)
- Max 25 users
- Max 1000 products
- All features
- Full API access
- Multi-location support
- Advanced analytics
- Priority support

### Enterprise (Custom)
- Unlimited users
- Unlimited products
- All features
- Full API access
- Multi-location support
- Advanced analytics
- White label branding
- Dedicated support
- Custom integrations

## Commands

### Create a New Company (Tenant)
```ruby
# Create company with subdomain
company = Company.create!(
  name: "Acme Equipment Rentals",
  subdomain: "acme",
  business_email: "info@acme.com",
  business_phone: "+1 555-0100",
  timezone: "America/New_York",
  default_currency: "USD",
  subscription_tier: :professional,
  status: :active,
  settings: {
    allow_online_booking: true,
    require_deposit: true,
    deposit_percentage: 25,
    cancellation_policy: "moderate",
    business_hours: {
      monday: "9:00-17:00",
      tuesday: "9:00-17:00",
      wednesday: "9:00-17:00",
      thursday: "9:00-17:00",
      friday: "9:00-17:00"
    }
  }
)

puts "Company created: #{company.name}"
puts "Subdomain: #{company.subdomain}"
puts "Access at: #{company.subdomain}.rentable.com"
```

### Create Admin User for Company
```ruby
# Within company context
ActsAsTenant.with_tenant(company) do
  admin = User.create!(
    name: "John Smith",
    email: "john@acme.com",
    password: "secure_password_123",
    password_confirmation: "secure_password_123",
    role: :admin,
    company: company,
    email_verified_at: Time.current
  )

  puts "Admin user created: #{admin.email}"
  puts "JWT Token:"
  puts admin.generate_jwt
end
```

### Complete Company Onboarding
```ruby
def onboard_company(params)
  company = Company.create!(
    name: params[:company_name],
    subdomain: params[:subdomain],
    business_email: params[:business_email],
    subscription_tier: :starter,
    status: :trial,
    trial_ends_at: 14.days.from_now
  )

  # Create admin user
  ActsAsTenant.with_tenant(company) do
    admin = User.create!(
      name: params[:admin_name],
      email: params[:admin_email],
      password: params[:admin_password],
      password_confirmation: params[:admin_password],
      role: :admin,
      company: company
    )

    # Create sample data (optional)
    create_sample_products(company) if params[:create_samples]

    # Send welcome email
    # CompanyMailer.welcome(company, admin).deliver_later

    puts "✓ Company onboarded: #{company.subdomain}"
    puts "✓ Admin created: #{admin.email}"
    puts "✓ Trial expires: #{company.trial_ends_at}"
    puts "✓ Access URL: https://#{company.subdomain}.rentable.com"

    return { company: company, admin: admin }
  end
end

# Usage
onboard_company(
  company_name: "Beta Rentals",
  subdomain: "beta",
  business_email: "info@beta.com",
  admin_name: "Jane Doe",
  admin_email: "jane@beta.com",
  admin_password: "secure_pass_456",
  create_samples: true
)
```

### Verify Data Isolation
```ruby
# Create two test companies
company_a = Company.create!(
  name: "Company A",
  subdomain: "company-a-test",
  business_email: "a@test.com",
  status: :active
)

company_b = Company.create!(
  name: "Company B",
  subdomain: "company-b-test",
  business_email: "b@test.com",
  status: :active
)

puts "Testing Data Isolation"
puts "=" * 80

# Create products in each company
ActsAsTenant.with_tenant(company_a) do
  Product.create!(
    name: "Company A Product",
    daily_price_cents: 10000,
    quantity: 5,
    active: true
  )
  puts "✓ Created product in Company A"
end

ActsAsTenant.with_tenant(company_b) do
  Product.create!(
    name: "Company B Product",
    daily_price_cents: 15000,
    quantity: 3,
    active: true
  )
  puts "✓ Created product in Company B"
end

# Verify isolation
ActsAsTenant.with_tenant(company_a) do
  count = Product.count
  products = Product.pluck(:name)
  puts "\nCompany A sees: #{count} products"
  puts "  - #{products.join(', ')}"
end

ActsAsTenant.with_tenant(company_b) do
  count = Product.count
  products = Product.pluck(:name)
  puts "\nCompany B sees: #{count} products"
  puts "  - #{products.join(', ')}"
end

# Test cross-tenant access prevention
product_a_id = nil
ActsAsTenant.with_tenant(company_a) do
  product_a_id = Product.first.id
end

ActsAsTenant.with_tenant(company_b) do
  begin
    Product.find(product_a_id)
    puts "\n❌ SECURITY BREACH: Company B accessed Company A's product!"
  rescue ActiveRecord::RecordNotFound
    puts "\n✅ Security verified: Cross-tenant access prevented"
  end
end

# Cleanup
company_a.destroy
company_b.destroy
puts "\n✓ Test companies cleaned up"
```

### Manage Subscription Tiers
```ruby
# Upgrade subscription
company = Company.find_by(subdomain: "acme")

puts "Current Subscription:"
puts "  Tier: #{company.subscription_tier}"
puts "  Status: #{company.status}"
puts "  Max Users: #{company.max_users}"
puts "  Max Products: #{company.max_products}"
puts ""

# Upgrade to professional
company.activate_subscription!(tier: :professional)

puts "After Upgrade:"
puts "  Tier: #{company.subscription_tier}"
puts "  Status: #{company.status}"
puts "  Max Users: #{company.max_users}"
puts "  Max Products: #{company.max_products}"
puts "  Features:"
puts "    - Multi-location: #{company.feature_enabled?(:multi_location)}"
puts "    - API access: #{company.feature_enabled?(:api_access)}"
puts "    - Advanced analytics: #{company.feature_enabled?(:advanced_analytics)}"
```

### Configure Company Branding
```ruby
company = Company.find_by(subdomain: "acme")

company.update!(
  logo: "https://acme.com/logo.png",
  primary_color: "#FF6B35",
  secondary_color: "#004E89",
  settings: company.settings.merge({
    company_tagline: "Professional Equipment Rentals",
    footer_text: "© 2026 Acme Equipment Rentals",
    contact_info: {
      phone: "+1 555-0100",
      email: "support@acme.com",
      address: "123 Main St, City, State 12345"
    }
  })
)

# Get branding info
branding = company.branding

puts "Company Branding:"
puts "  Name: #{branding[:company_name]}"
puts "  Logo: #{branding[:logo]}"
puts "  Primary Color: #{branding[:primary_color]}"
puts "  Secondary Color: #{branding[:secondary_color]}"
puts "  Timezone: #{branding[:timezone]}"
puts "  Currency: #{branding[:currency]}"
```

### Check Feature Access
```ruby
company = Company.find_by(subdomain: "acme")

features = [
  :multi_location,
  :api_access,
  :advanced_analytics,
  :white_label,
  :custom_domain,
  :priority_support
]

puts "Feature Access for #{company.name} (#{company.subscription_tier}):"
puts "=" * 80

features.each do |feature|
  enabled = company.feature_enabled?(feature)
  status = enabled ? "✓ Enabled" : "✗ Disabled"
  puts "  #{feature.to_s.titleize.ljust(25)} #{status}"
end

puts ""
puts "Limits:"
puts "  Max Users: #{company.max_users}"
puts "  Max Products: #{company.max_products}"
puts "  Max Bookings/Month: #{company.max_bookings_per_month}"
```

### Manage Trial Period
```ruby
# Start trial
company = Company.find_by(subdomain: "new-company")

if company.status == :trial
  puts "Trial Status:"
  puts "  Expires: #{company.trial_ends_at}"
  puts "  Days Remaining: #{company.trial_days_remaining}"
  puts "  On Trial: #{company.on_trial?}"

  if company.trial_days_remaining <= 3
    puts "\n⚠️  Trial expiring soon!"
    # Send notification email
  end
end

# Convert trial to paid
if company.on_trial?
  company.activate_subscription!(
    tier: :professional,
    stripe_customer_id: "cus_xxxxx",
    stripe_subscription_id: "sub_xxxxx"
  )

  puts "\n✓ Trial converted to paid subscription"
  puts "  Status: #{company.status}"
  puts "  Tier: #{company.subscription_tier}"
end
```

### Bulk Operations Across Tenants
```ruby
# Run operation for all active companies
Company.where(status: :active).find_each do |company|
  ActsAsTenant.with_tenant(company) do
    puts "Processing: #{company.name}"

    # Example: Calculate monthly metrics
    bookings_count = Booking.where(
      "created_at >= ? AND created_at <= ?",
      1.month.ago,
      Date.today
    ).count

    revenue = Booking.where(
      "created_at >= ? AND created_at <= ?",
      1.month.ago,
      Date.today
    ).where(status: [:paid, :completed])
     .sum(:grand_total_cents)

    puts "  Bookings: #{bookings_count}"
    puts "  Revenue: $#{revenue / 100.0}"
    puts ""

    # Update company metrics
    company.update!(
      settings: company.settings.merge({
        last_month_bookings: bookings_count,
        last_month_revenue: revenue
      })
    )
  end
end
```

### Find Company by Subdomain or Domain
```ruby
# By subdomain
company = Company.find_by_domain("acme")
puts "Found by subdomain: #{company.name}"

# By custom domain
company = Company.find_by_domain("rentals.acme.com")
puts "Found by custom domain: #{company.name}"

# Get primary domain
puts "Primary domain: #{company.primary_domain}"
# Returns: "acme.rentable.com" or custom domain if set
```

### Set Tenant Context in Controllers
```ruby
# In ApplicationController or API controller
class ApplicationController < ActionController::API
  include SetCurrentTenant

  before_action :set_current_tenant

  private

  def set_current_tenant
    company = find_company_from_request

    if company
      ActsAsTenant.current_tenant = company
    else
      render json: { error: "Company not found" }, status: :not_found
    end
  end

  def find_company_from_request
    # Extract from subdomain
    subdomain = request.subdomain

    # Or from custom header
    subdomain ||= request.headers['X-Company-Subdomain']

    # Or from JWT token
    if current_user
      current_user.company
    else
      Company.find_by_domain(subdomain)
    end
  end
end
```

## API Endpoints

```bash
# Company signup
POST /api/v1/companies/signup

# Check subdomain availability
GET /api/v1/companies/check_subdomain?subdomain=acme

# Get company settings
GET /api/v1/companies/current

# Update company settings
PATCH /api/v1/companies/current

# Get company branding
GET /api/v1/companies/branding

# Update company branding
PATCH /api/v1/companies/branding
```

## Best Practices

1. **Always use tenant context**: Wrap all queries in `ActsAsTenant.with_tenant`
2. **Validate company_id**: Ensure users can't access other companies
3. **Use subdomain routing**: Automatically set tenant from subdomain
4. **Feature flags**: Check `feature_enabled?` before allowing premium features
5. **Enforce limits**: Check max_users, max_products before creation
6. **Trial management**: Monitor trial expiration and send notifications
7. **Audit tenant switching**: Log when switching between tenants

## Common Scenarios

### Scenario 1: New Company Signup Flow
```ruby
# 1. Validate subdomain
subdomain = "acme"
if Company.exists?(subdomain: subdomain)
  return { error: "Subdomain already taken" }
end

# 2. Create company
company = Company.create!(
  name: "Acme Rentals",
  subdomain: subdomain,
  business_email: "info@acme.com",
  subscription_tier: :starter,
  status: :trial,
  trial_ends_at: 14.days.from_now
)

# 3. Create admin user
ActsAsTenant.with_tenant(company) do
  admin = User.create!(
    name: "John Doe",
    email: "john@acme.com",
    password: "password123",
    password_confirmation: "password123",
    role: :admin,
    company: company
  )

  # 4. Generate access token
  token = admin.generate_jwt

  # 5. Return signup response
  {
    company: {
      id: company.id,
      name: company.name,
      subdomain: company.subdomain,
      url: "https://#{company.subdomain}.rentable.com"
    },
    user: {
      id: admin.id,
      email: admin.email,
      name: admin.name
    },
    token: token,
    trial_expires_at: company.trial_ends_at
  }
end
```

### Scenario 2: Enforce Subscription Limits
```ruby
ActsAsTenant.with_tenant(company) do
  # Check user limit
  if User.count >= company.max_users
    raise "User limit reached (#{company.max_users}). Please upgrade your plan."
  end

  # Check product limit
  if Product.count >= company.max_products
    raise "Product limit reached (#{company.max_products}). Please upgrade your plan."
  end

  # Check feature access
  unless company.feature_enabled?(:multi_location)
    raise "Multi-location is not available in your plan. Please upgrade."
  end

  # Proceed with operation
  User.create!(...)
end
```

## Troubleshooting

**ActsAsTenant not set**: Ensure you wrap operations in `with_tenant` block
**Cross-tenant data visible**: Check that `company_id` is indexed and scoped
**Feature not working**: Verify subscription tier and feature gates
**Subdomain not resolving**: Check DNS configuration and routing
**Trial expired**: Check trial_ends_at and status fields

## Related Skills
- rental-equipment-manager
- booking-workflow-manager
- api-tester
- database-reporter
