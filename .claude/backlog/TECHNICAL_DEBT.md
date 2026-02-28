# Technical Debt Log

**Last Updated**: February 28, 2026
**Owner**: Engineering Team
**Review Frequency**: Monthly

---

## Overview

This document tracks known technical debt in the Rentable platform. Each item is prioritized and estimated for effort. We allocate 20% of sprint capacity to addressing technical debt.

### Current Stats
- **Total Items**: 8 (1 completed)
- **High Priority**: 2 (1 completed)
- **Medium Priority**: 4
- **Low Priority**: 1
- **Estimated Total Effort**: 53 story points (5 completed)

---

## High Priority Technical Debt

### TD-001: Refactor Booking Availability Logic

**Priority**: HIGH
**Effort**: 8 points
**Impact**: Code maintainability, performance
**Created**: 2026-02-15
**Target Sprint**: Sprint 20

**Problem**:
The `BookingService.calculate_availability` method has grown to 200+ lines with complex nested conditionals. Logic for:
- Overlapping bookings
- Maintenance blocks
- Manual availability overrides
- Multi-location inventory

All mixed together, making it difficult to add new availability rules (e.g., calendar integrations).

**Impact**:
- New developers struggle to understand the code
- High bug risk when adding features
- Slow performance (N+1 queries)
- Difficult to test all edge cases

**Proposed Solution**:
```ruby
# Extract to AvailabilityService with strategy pattern
class AvailabilityService
  def initialize(product)
    @product = product
    @rules = [
      BookingOverlapRule.new,
      MaintenanceBlockRule.new,
      ManualOverrideRule.new,
      LocationInventoryRule.new
    ]
  end

  def available?(start_date, end_date, quantity: 1)
    @rules.all? { |rule| rule.check(@product, start_date, end_date, quantity) }
  end
end
```

**Benefits**:
- Each rule is independently testable
- Easy to add new rules (Open/Closed Principle)
- Better performance (optimize per rule)
- Clear separation of concerns

**Tasks**:
- [ ] Create AvailabilityService and rule classes
- [ ] Migrate existing logic to rules
- [ ] Add comprehensive tests
- [ ] Update controllers to use new service
- [ ] Performance benchmark (should be faster)
- [ ] Remove old BookingService availability code

**Risks**:
- Breaking changes if not careful
- Need extensive regression testing

---

### TD-002: Add Database Indexes for Performance ✅ COMPLETED

**Priority**: HIGH
**Effort**: 5 points
**Impact**: Performance, scalability
**Created**: 2026-02-20
**Completed**: 2026-02-28
**Target Sprint**: Sprint 18

**Problem**:
Several critical queries were missing indexes, causing slow performance as data grows:

```sql
-- Slow query 1: Find bookings by date range (used on availability page)
SELECT * FROM bookings WHERE start_date >= '2026-03-01' AND end_date <= '2026-03-31';
-- Missing index on (start_date, end_date)

-- Slow query 2: Find products by company and category
SELECT * FROM products WHERE company_id = 123 AND category_id = 5;
-- Missing composite index on (company_id, category_id)

-- Slow query 3: Payment lookup by Stripe ID
SELECT * FROM payments WHERE stripe_payment_intent_id = 'pi_123';
-- Missing index on stripe_payment_intent_id

-- Slow query 4: User bookings for dashboard
SELECT * FROM bookings WHERE customer_id = 456 ORDER BY start_date DESC;
-- Missing index on (customer_id, start_date)
```

**Impact**:
- Slow API responses (500ms+ for some queries)
- Poor user experience on dashboards
- Database CPU spikes during peak load
- Cannot scale beyond 10,000 bookings

**Proposed Solution**:
```ruby
class AddPerformanceIndexes < ActiveRecord::Migration[7.0]
  def change
    # Booking queries
    add_index :bookings, [:start_date, :end_date], name: 'idx_bookings_date_range'
    add_index :bookings, [:customer_id, :start_date], name: 'idx_bookings_customer_date'
    add_index :bookings, [:product_id, :status], name: 'idx_bookings_product_status'

    # Product queries
    add_index :products, [:company_id, :category_id], name: 'idx_products_company_category'
    add_index :products, [:company_id, :status], name: 'idx_products_company_status'

    # Payment queries
    add_index :payments, :stripe_payment_intent_id, unique: true, name: 'idx_payments_stripe_id'
    add_index :payments, [:booking_id, :status], name: 'idx_payments_booking_status'

    # User/Auth queries
    add_index :users, [:company_id, :role], name: 'idx_users_company_role'
  end
end
```

**Benefits**:
- 10-50x faster query performance
- Better scalability
- Lower database CPU usage
- Improved user experience

**Tasks**:
- [x] Analyze slow query log
- [x] Identify missing indexes
- [x] Create migration
- [x] Test on development database
- [x] Deploy indexes successfully

**Results**:
- **14 new performance indexes** added across 5 critical tables
- **Bookings table**: 6 new composite indexes for date ranges, status filtering, AR aging, and lead tracking
- **Products table**: 4 new indexes for catalog filtering, maintenance tracking, and inventory management
- **Payments table**: 1 new composite index for payment history queries
- **Users table**: 1 new index for company/role lookups
- **Booking line items**: 2 new indexes for polymorphic queries and tax calculations

**Migration File**: `db/migrate/20260228155159_add_performance_indexes_to_bookings_and_products.rb`

**Impact**:
- Dramatically improved query performance for date range queries (availability checking)
- Faster customer booking history lookups
- Optimized AR aging reports and overdue payment tracking
- Better performance for product catalog filtering
- Efficient quote management queries

---

### TD-003: Upgrade Rails 7.0 to 7.2

**Priority**: HIGH
**Effort**: 13 points
**Impact**: Security, performance, features
**Created**: 2026-01-15
**Target Sprint**: Sprint 21

**Problem**:
Currently on Rails 7.0.8. Rails 7.2 offers:
- Security patches
- Performance improvements (Solid Queue, Solid Cache)
- Better query optimization
- Async queries
- Modern features we want to use

**Impact**:
- Missing security patches
- Missing performance optimizations
- Cannot use new Rails 7.2 features
- Technical gap growing larger over time

**Proposed Approach**:
1. Update Gemfile: `gem 'rails', '~> 7.2.0'`
2. Run `bundle update rails`
3. Run `rails app:update` to get new framework defaults
4. Review deprecation warnings
5. Update configuration files
6. Test thoroughly

**Risks**:
- Breaking changes in dependencies
- Need to update multiple gems
- Extensive testing required

**Tasks**:
- [ ] Create upgrade branch
- [ ] Update Rails gem
- [ ] Update related gems (pg, puma, etc.)
- [ ] Run full test suite
- [ ] Fix deprecation warnings
- [ ] Manual QA testing
- [ ] Performance testing
- [ ] Deploy to staging
- [ ] Monitor for issues

**Estimated Downtime**: None (rolling deployment)

---

## Medium Priority Technical Debt

### TD-004: Consolidate Duplicate Code in Controllers

**Priority**: MEDIUM
**Effort**: 5 points
**Impact**: Code maintainability
**Created**: 2026-02-10
**Target Sprint**: Sprint 22

**Problem**:
Many controllers have duplicate patterns:
- Authentication checks
- Company scoping
- Error handling
- Pagination
- JSON response formatting

Example duplication:
```ruby
# In ProductsController
before_action :authenticate_user!
before_action :set_company

def index
  @products = @company.products.page(params[:page]).per(25)
  render json: @products, status: :ok
rescue => e
  render json: { error: e.message }, status: :internal_server_error
end

# Same pattern in BookingsController, CustomersController, etc.
```

**Proposed Solution**:
```ruby
# Base controller with common patterns
class Api::V1::BaseController < ApplicationController
  include Authentication
  include CompanyScoping
  include ErrorHandling
  include Pagination
  include JsonResponses

  # Shared before_actions, rescue_from, etc.
end

# Then inherit
class Api::V1::ProductsController < Api::V1::BaseController
  def index
    @products = paginate(@company.products)
    render_success(@products)
  end
end
```

**Benefits**:
- DRY code
- Consistent error handling
- Easier to add new controllers
- Single place to update common logic

**Effort**: 5 points

---

### TD-005: Improve Test Coverage for Edge Cases

**Priority**: MEDIUM
**Effort**: 8 points
**Impact**: Quality, bug prevention
**Created**: 2026-02-05
**Target Sprint**: Sprint 23

**Problem**:
While we have 85% test coverage, many edge cases are untested:
- Timezone handling in bookings
- Concurrent booking attempts (race conditions)
- Payment failures and retries
- Null/empty data handling
- Large dataset performance

**Missing Test Coverage**:
- Booking model: Edge cases around date boundaries
- Payment processing: Stripe webhook failures
- Multi-tenancy: Data isolation between companies
- Background jobs: Retry logic and failure handling

**Proposed Solution**:
Add test cases for:
```ruby
# Booking edge cases
it 'handles booking across daylight saving time change'
it 'prevents double-booking with concurrent requests' (race condition)
it 'handles booking when product has no images'
it 'validates booking dates in different timezones'

# Payment edge cases
it 'retries failed payment after network timeout'
it 'handles duplicate Stripe webhook deliveries (idempotency)'
it 'rolls back booking when payment fails'

# Multi-tenancy edge cases
it 'prevents company A from accessing company B data'
it 'handles user switching between companies'
```

**Benefits**:
- Catch bugs before production
- Confidence in refactoring
- Documentation of expected behavior

**Effort**: 8 points

---

### TD-006: Replace Hardcoded Configuration with Settings Table

**Priority**: MEDIUM
**Effort**: 5 points
**Impact**: Flexibility
**Created**: 2026-02-01
**Target Sprint**: Sprint 24

**Problem**:
Many business rules are hardcoded:
```ruby
# In code
DEFAULT_BOOKING_DURATION = 1.day
MAX_ADVANCE_BOOKING_DAYS = 365
LATE_FEE_PERCENTAGE = 10
CANCELLATION_WINDOW_HOURS = 24
```

Should be per-company configurable settings.

**Proposed Solution**:
```ruby
class CompanySetting < ApplicationRecord
  belongs_to :company

  SETTINGS = {
    default_booking_duration_days: 1,
    max_advance_booking_days: 365,
    late_fee_percentage: 10,
    cancellation_window_hours: 24,
    tax_rate_percentage: 8.5,
    require_deposit: true,
    deposit_percentage: 25
  }

  # company.setting(:late_fee_percentage) => 10
end
```

**Benefits**:
- Per-company customization
- No code deploy to change settings
- Admin UI to manage settings
- Different policies per customer

**Effort**: 5 points

---

### TD-007: Add Monitoring and Error Tracking

**Priority**: MEDIUM
**Effort**: 8 points
**Impact**: Observability
**Created**: 2026-01-20
**Target Sprint**: Sprint 25

**Problem**:
Limited visibility into production issues:
- No centralized error tracking (Sentry, Rollbar)
- No performance monitoring (New Relic, Scout)
- No uptime monitoring
- Logs scattered, hard to search

**Proposed Solution**:
1. **Error Tracking**: Sentry
   ```ruby
   gem 'sentry-ruby'
   gem 'sentry-rails'
   ```

2. **Performance Monitoring**: Scout APM
   ```ruby
   gem 'scout_apm'
   ```

3. **Uptime Monitoring**: UptimeRobot (external service)

4. **Log Aggregation**: Consider Papertrail or Datadog

**Benefits**:
- Catch errors before customers report them
- Performance bottleneck identification
- Historical performance data
- Proactive alerting

**Cost**: ~$100-200/month for tools

**Effort**: 8 points

---

## Low Priority Technical Debt

### TD-008: Migrate from Asset Pipeline to Propshaft

**Priority**: LOW
**Effort**: 5 points
**Impact**: Modern tooling
**Created**: 2026-02-20
**Target Sprint**: TBD

**Problem**:
Still using Sprockets (Rails Asset Pipeline). Rails 7+ recommends Propshaft or importmaps.

**Impact**:
- Slower asset compilation
- Missing modern features
- Deprecated tooling

**Proposed Solution**:
Migrate to Propshaft for simpler asset handling.

**Effort**: 5 points
**Priority**: Low (not urgent)

---

## Technical Debt Metrics

### Debt by Category
| Category | Count | Total Points |
|----------|-------|--------------|
| Performance | 2 | 13 |
| Code Quality | 2 | 10 |
| Testing | 1 | 8 |
| Infrastructure | 2 | 21 |
| Tooling | 1 | 5 |
| **TOTAL** | **8** | **58** |

### Debt by Priority
| Priority | Count | Total Points | Avg Points | Completed |
|----------|-------|--------------|------------|-----------|
| High | 3 | 26 | 8.7 | 1 (TD-002) |
| Medium | 4 | 27 | 6.8 | 0 |
| Low | 1 | 5 | 5.0 | 0 |

---

## Technical Debt Reduction Plan

### Sprint Allocation
- **Sprint 18**: ~~TD-002 (Database indexes) - 5 pts~~ ✅ **COMPLETED 2026-02-28**
- **Sprint 20**: TD-001 (Refactor availability) - 8 pts
- **Sprint 21**: TD-003 (Rails upgrade) - 13 pts
- **Sprint 22**: TD-004 (Controller consolidation) - 5 pts
- **Sprint 23**: TD-005 (Test coverage) - 8 pts
- **Sprint 24**: TD-006 (Settings table) - 5 pts
- **Sprint 25**: TD-007 (Monitoring) - 8 pts
- **Later**: TD-008 (Propshaft migration) - 5 pts

### Capacity Allocation
- **20% rule**: Each sprint allocates ~10-12 points to tech debt
- **Dedicated sprints**: Every 5th sprint is 50% tech debt focus

---

## Preventing New Technical Debt

### Code Review Checklist
- [ ] Are there appropriate indexes for new queries?
- [ ] Is business logic extracted to services (not in controllers)?
- [ ] Are edge cases tested?
- [ ] Is configuration externalized (not hardcoded)?
- [ ] Is error handling comprehensive?
- [ ] Is the code DRY (no duplication)?

### Architecture Decision Records (ADRs)
Document major decisions to prevent future questioning:
- Why we chose Rails over Django
- Why we chose PostgreSQL over MySQL
- Why we use Stripe for payments
- Why we chose multi-tenancy with row-level security

---

## Debt Review Process

### Monthly Tech Debt Review
**When**: Last Friday of each month
**Who**: Engineering team + Product Owner
**Agenda**:
1. Review existing debt items (still relevant?)
2. Reprioritize based on impact
3. Add newly discovered debt
4. Allocate to upcoming sprints
5. Celebrate debt eliminated

### Adding New Debt Items
```markdown
### TD-XXX: [Title]

**Priority**: HIGH | MEDIUM | LOW
**Effort**: [story points]
**Impact**: [What's affected]
**Created**: [Date]
**Target Sprint**: [Sprint number]

**Problem**: [Describe the issue]
**Impact**: [What's the cost of not fixing]
**Proposed Solution**: [How to fix]
**Benefits**: [Why fix this]
**Effort**: [Estimate]
```

---

## Success Metrics

### Goals for 2026
- [ ] Reduce high-priority debt to 0 by Q3 2026
- [ ] Maintain <20 total debt items
- [ ] Address at least 1 debt item per sprint
- [ ] Prevent new high-priority debt from being created

### Tracking
- **Debt Trend**: Decreasing over time
- **Debt Age**: No item older than 6 months without being addressed
- **Debt Ratio**: Tech debt points < 10% of feature points

---

## Changelog

| Date | Change | Author |
|------|--------|--------|
| 2026-02-28 | ✅ Completed TD-002: Added 14 performance indexes to critical tables | Database Administrator |
| 2026-02-28 | Initial technical debt log created | Product Owner |
