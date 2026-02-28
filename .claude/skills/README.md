# Rentable Claude Skills

This directory contains specialized Claude skills for managing the Rentable equipment rental SaaS platform.

## Available Skills

### 1. 🏗️ Rental Equipment Manager
**Location**: `rental-equipment-manager/`

Manages the complete lifecycle of rental equipment including products, kits, inventory, and availability tracking.

**Use when you need to**:
- Add or update rental products
- Create equipment kits/bundles
- Check availability for date ranges
- Manage product instances (serialized items)
- Handle product variants
- Generate inventory reports

**Key Features**:
- Product CRUD operations
- Kit management
- Availability checking with clash prevention
- Product instance tracking
- Variant management
- Inventory reporting

---

### 2. 📅 Booking Workflow Manager
**Location**: `booking-workflow-manager/`

Handles the complete booking lifecycle from creation to completion.

**Use when you need to**:
- Create and manage bookings
- Process payments via Stripe
- Handle cancellations and refunds
- Generate quotes/estimates
- Manage recurring bookings
- Track overdue returns

**Key Features**:
- Full booking lifecycle management
- Payment integration
- Cancellation policies (flexible, moderate, strict, no refund)
- Quote/estimate generation
- Recurring booking support
- Late fee calculation

---

### 3. 🧪 API Tester & Debugger
**Location**: `api-tester/`

Comprehensive API testing and debugging capabilities.

**Use when you need to**:
- Test API endpoints
- Generate JWT tokens
- Debug authentication issues
- Verify multi-tenant isolation
- Test payment workflows
- Performance test the API

**Key Features**:
- JWT token generation
- Complete endpoint testing
- Multi-tenancy verification
- Payment testing
- Performance benchmarking
- Debug helpers

---

### 4. 📊 Database Query & Reporting
**Location**: `database-reporter/`

Generate comprehensive reports and analytics from the database.

**Use when you need to**:
- Generate revenue reports
- Analyze equipment utilization
- Track customer patterns
- Review inventory status
- Create AR aging reports
- Export data to CSV

**Key Features**:
- Financial reporting
- Utilization analytics
- Customer insights
- Inventory reports
- AR aging reports
- Data export capabilities

---

### 5. 🏢 Multi-Tenancy Manager
**Location**: `multi-tenancy-manager/`

Manage companies, subscriptions, and tenant isolation.

**Use when you need to**:
- Create new companies (tenants)
- Manage subscriptions
- Configure company settings
- Verify data isolation
- Handle feature gates
- Manage user-company relationships

**Key Features**:
- Company onboarding
- Subscription tier management (Free, Starter, Professional, Enterprise)
- Feature gates and limits
- Data isolation verification
- Branding customization
- Trial management

---

## Quick Start

### Using Skills

Skills are loaded automatically by Claude. Simply reference them in your requests:

```
"Create a new product using the rental equipment manager skill"
"Generate a revenue report for the last month"
"Test the booking API endpoints"
"Onboard a new company with the subdomain 'acme'"
```

### Common Workflows

#### 1. Complete Company Setup
```
1. Use multi-tenancy-manager to create company
2. Use rental-equipment-manager to add products
3. Use booking-workflow-manager to create test booking
4. Use api-tester to verify everything works
```

#### 2. Monthly Business Review
```
1. Use database-reporter for revenue reports
2. Use database-reporter for utilization analysis
3. Use database-reporter for AR aging report
4. Export data for executive presentation
```

#### 3. New Equipment Launch
```
1. Use rental-equipment-manager to add products
2. Use rental-equipment-manager to create bundles
3. Use api-tester to verify availability
4. Use booking-workflow-manager to test bookings
```

## Skill Architecture

Each skill follows this structure:

```
skill-name/
├── skill.md              # Main skill documentation
└── examples/             # Usage examples (optional)
```

## Multi-Tenancy Context

**Important**: All operations must be wrapped in tenant context:

```ruby
company = Company.find_by(subdomain: "acme")

ActsAsTenant.with_tenant(company) do
  # All database operations here are scoped to this company
  Product.all  # Returns only acme's products
end
```

## API Authentication

Most API operations require JWT authentication:

```ruby
# Generate token
user = User.find_by(email: "admin@example.com")
token = user.generate_jwt

# Use in API requests
curl -H "Authorization: Bearer #{token}" http://localhost:4000/api/v1/products
```

## Database Structure

### Core Models
- **Company**: Tenant/organization
- **User**: System users (scoped to company)
- **Client**: Customers/renters (scoped to company)
- **Product**: Rental items
- **Kit**: Product bundles
- **ProductInstance**: Individual serialized items
- **Booking**: Rental reservations
- **BookingLineItem**: Items in a booking

### Financial Models
- **Payment**: Payment records
- **TaxRate**: Tax configuration
- **PricingRule**: Dynamic pricing

### Supporting Models
- **Location**: Physical locations
- **Contract**: Rental agreements
- **DamageReport**: Equipment damage tracking
- **MaintenanceJob**: Equipment maintenance

## Best Practices

### 1. Always Use Tenant Context
```ruby
# ✅ Good
ActsAsTenant.with_tenant(company) do
  Product.create!(...)
end

# ❌ Bad
Product.create!(...)  # Missing tenant context
```

### 2. Check Availability Before Booking
```ruby
# ✅ Good
if product.available_quantity(start_date, end_date) >= quantity
  create_booking
end

# ❌ Bad
create_booking  # No availability check
```

### 3. Handle Money Properly
```ruby
# ✅ Good
product.daily_price.format  # "$150.00"

# ❌ Bad
product.daily_price_cents  # 15000 (raw cents)
```

### 4. Use Reference Numbers
```ruby
# ✅ Good
booking = Booking.find_by(reference_number: "BK20260226820B8670")

# ❌ Bad - exposes internal IDs
booking = Booking.find(29)
```

## Subscription Tiers

| Feature | Free | Starter | Professional | Enterprise |
|---------|------|---------|--------------|------------|
| Users | 1 | 5 | 25 | Unlimited |
| Products | 10 | 100 | 1000 | Unlimited |
| API Access | ❌ | Limited | ✅ | ✅ |
| Multi-location | ❌ | ❌ | ✅ | ✅ |
| Analytics | ❌ | Basic | Advanced | Advanced |
| White Label | ❌ | ❌ | ❌ | ✅ |
| Support | Community | Email | Priority | Dedicated |

## Environment Variables

Required environment variables:

```bash
# Database
DATABASE_URL=postgresql://...

# JWT
JWT_SECRET_KEY=your_secret_key_here

# Stripe
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Application
RAILS_ENV=development
PORT=4000
```

## Testing

### Run Skill Examples
```bash
# Test product creation
bin/rails runner .claude/skills/rental-equipment-manager/examples/create_product.rb

# Test booking flow
bin/rails runner .claude/skills/booking-workflow-manager/examples/complete_flow.rb

# Generate reports
bin/rails runner .claude/skills/database-reporter/examples/monthly_report.rb
```

### API Testing
```bash
# Get JWT token
curl http://localhost:4000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@test.com", "password": "password123"}'

# Test endpoint
curl http://localhost:4000/api/v1/products \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Troubleshooting

### Common Issues

**"ActsAsTenant not set"**
- Ensure operations are wrapped in `ActsAsTenant.with_tenant` block

**"401 Unauthorized"**
- JWT token expired - generate a new one
- Token not included in Authorization header

**"404 Not Found"**
- Resource doesn't exist in current tenant scope
- Check company_id scoping

**"422 Unprocessable Entity"**
- Validation failed - check error messages
- Required fields missing

**"Money calculation wrong"**
- Ensure using Money objects, not raw cents
- Use `.format` for display

## Support

### Documentation
- Main README: `/README.md`
- API Documentation: `/API_DOCUMENTATION.md`
- Implementation Guide: `/IMPLEMENTATION_COMPLETE.md`
- Multi-Tenancy Guide: `/MULTI_TENANCY_COMPLETE.md`

### Getting Help
- Check skill documentation in respective directories
- Review examples in skill folders
- Check Rails logs: `tail -f log/development.log`
- Use api-tester skill to debug issues

## Contributing

To create a new skill:

1. Create directory: `.claude/skills/skill-name/`
2. Create `skill.md` with:
   - Description
   - When to use
   - Commands/examples
   - Best practices
   - Related skills
3. Add to this README
4. Test thoroughly

## Version

- Rentable Version: 1.0.0
- Skills Last Updated: 2026-02-28
- Rails Version: 8.1.2
- PostgreSQL: Required

---

**Built with ❤️ for efficient equipment rental management**
