# Product Variant System - Comprehensive Implementation Plan

**Date:** February 26, 2026  
**Status:** Planning Phase  
**Goal:** E-commerce style product variants with options (size, color, etc.)

---

## 1. CURRENT STATE ANALYSIS

### Existing Features ✅
- **Product Model**: Base product with pricing, inventory, categories
- **ProductInstance**: Individual serialized items (serial numbers, conditions)
- **custom_fields (JSONB)**: Flexible attributes storage
- **specifications (JSONB)**: Technical specs
- **Multi-tenancy**: company_id scoping
- **Monetization**: Multiple price points (daily, weekly, weekend)
- **Inventory**: Quantity tracking

### Current Limitations ❌
- No structured variant options (size, color, material)
- No separate SKU per variant
- No variant-specific pricing
- No variant-specific inventory
- No variant images
- Cannot show "5 colors available"

---

## 2. REQUIREMENTS ANALYSIS

### Business Requirements
1. **Multiple Variants per Product**: One base product, multiple variants
2. **Option Types**: Size, Color, Material, Storage, etc.
3. **Variant-Specific Data**:
   - Unique SKU per variant
   - Independent pricing (can differ from base)
   - Separate inventory count
   - Variant-specific images
   - Barcode per variant
4. **Booking Integration**: Customers book specific variants
5. **Inventory Management**: Track availability per variant
6. **API Support**: Full CRUD for variants

### Technical Requirements
1. **Scalability**: Support 1000s of products with 10+ variants each
2. **Performance**: Fast queries for variant availability
3. **Multi-tenancy**: Variants scoped by company_id
4. **Backward Compatibility**: Existing products without variants work
5. **Data Integrity**: Cascading deletes, foreign keys

---

## 3. ARCHITECTURE DESIGN

### Database Schema

#### Option 1: Separate Tables (Recommended) ⭐
```
products (base product)
  ├── id
  ├── name: "T-Shirt"
  ├── description
  ├── category
  ├── has_variants: boolean
  ├── company_id
  └── ...existing fields

product_variants (individual variants)
  ├── id (UUID for security)
  ├── product_id → products.id
  ├── sku: "TSHIRT-RED-L" (unique)
  ├── barcode: "123456789"
  ├── variant_name: "Red / Large"
  ├── price_cents (can override product price)
  ├── price_currency
  ├── stock_quantity
  ├── position (sort order)
  ├── active: boolean
  ├── company_id (for multi-tenancy)
  └── timestamps

variant_options (size: Large, color: Red)
  ├── id
  ├── product_variant_id → product_variants.id
  ├── option_name: "color"
  ├── option_value: "Red"
  ├── position
  └── timestamps

variant_images (variant-specific photos)
  ├── product_variant_id
  ├── image (Active Storage attachment)
  └── position
```

**Pros:**
- Clean separation of concerns
- Easy to query variants
- Flexible option system
- Can add variant-specific fields easily

**Cons:**
- More tables to manage
- More joins for queries

#### Option 2: JSONB Embedded (Alternative)
```
products
  └── variants: JSONB [
        {
          sku: "TSHIRT-RED-L",
          options: { color: "Red", size: "Large" },
          price_cents: 2000,
          stock: 50
        }
      ]
```

**Pros:**
- Simpler schema
- Fewer joins

**Cons:**
- Harder to query variants
- Less flexible
- No referential integrity
- Harder to maintain inventory

**Decision:** ✅ **Use Option 1 (Separate Tables)** for better data integrity and queryability

---

## 4. DETAILED MODEL DESIGN

### ProductVariant Model

```ruby
class ProductVariant < ApplicationRecord
  include ActsAsTenant
  has_paper_trail
  
  # Associations
  belongs_to :product
  belongs_to :company
  has_many :variant_options, dependent: :destroy
  has_many :booking_line_items, as: :bookable
  has_many_attached :images
  
  # Monetize
  monetize :price_cents, with_model_currency: :price_currency, allow_nil: true
  monetize :compare_at_price_cents, with_model_currency: :price_currency, allow_nil: true
  
  # Validations
  validates :sku, presence: true, uniqueness: { scope: :company_id }
  validates :barcode, uniqueness: { scope: :company_id }, allow_blank: true
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  
  # Scopes
  scope :active, -> { where(active: true) }
  scope :in_stock, -> { where('stock_quantity > ?', 0) }
  scope :low_stock, ->(threshold = 5) { where('stock_quantity <= ?', threshold) }
  
  # Methods
  def available_for_booking?(quantity = 1)
    active? && stock_quantity >= quantity
  end
  
  def display_name
    return product.name unless variant_name.present?
    "#{product.name} - #{variant_name}"
  end
  
  def option_values
    variant_options.pluck(:option_name, :option_value).to_h
  end
  
  def effective_price
    price || product.daily_price
  end
  
  def decrease_stock!(quantity)
    update!(stock_quantity: stock_quantity - quantity)
  end
  
  def increase_stock!(quantity)
    update!(stock_quantity: stock_quantity + quantity)
  end
end
```

### VariantOption Model

```ruby
class VariantOption < ApplicationRecord
  belongs_to :product_variant
  
  validates :option_name, presence: true
  validates :option_value, presence: true
  validates :option_name, uniqueness: { scope: :product_variant_id }
  
  # Common option names
  OPTION_TYPES = %w[
    size color material storage memory style
    capacity voltage width height length weight
  ].freeze
  
  validates :option_name, inclusion: { in: OPTION_TYPES }
end
```

### Product Model Updates

```ruby
class Product < ApplicationRecord
  # Add to existing associations
  has_many :product_variants, dependent: :destroy
  
  # Add attribute
  attribute :has_variants, :boolean, default: false
  
  # New methods
  def variants_enabled?
    has_variants && product_variants.any?
  end
  
  def available_variants
    product_variants.active.in_stock
  end
  
  def total_variant_stock
    product_variants.sum(:stock_quantity)
  end
  
  def variant_options_config
    # Returns: { "size" => ["S", "M", "L"], "color" => ["Red", "Blue"] }
    product_variants.includes(:variant_options).flat_map(&:variant_options)
      .group_by(&:option_name)
      .transform_values { |opts| opts.map(&:option_value).uniq.sort }
  end
end
```

---

## 5. PRICING STRATEGY

### Inheritance vs Independent Pricing

**Approach:** Hybrid (Recommended) ⭐

```ruby
# Variant can override product price or use product's price
def effective_price
  price_cents.present? ? price : product.daily_price
end

# Examples:
# Base product: T-Shirt = $20/day
# Variant: Small/Red = $20/day (inherits)
# Variant: XL/Blue = $25/day (override - larger size premium)
# Variant: Limited/Gold = $50/day (override - rare color)
```

**Rules:**
1. If `variant.price_cents` is NULL → use `product.daily_price`
2. If `variant.price_cents` is SET → use variant price
3. Pricing API shows both: `base_price` and `variant_price`

---

## 6. INVENTORY MANAGEMENT

### Stock Tracking

**Two-Level System:**

1. **Product Level** (for non-variant products)
   - `product.quantity` - used when `has_variants = false`
   
2. **Variant Level** (for variant products)
   - `product_variant.stock_quantity` - used when `has_variants = true`
   - `product.quantity` ignored when variants exist

**Stock Operations:**

```ruby
# Booking a variant
def book_variant(variant, quantity)
  raise "Insufficient stock" unless variant.stock_quantity >= quantity
  
  variant.decrease_stock!(quantity)
  
  # Create booking line item
  BookingLineItem.create!(
    booking: booking,
    bookable: variant,  # Polymorphic: bookable_type = "ProductVariant"
    quantity: quantity
  )
end

# Returning a variant
def return_variant(variant, quantity)
  variant.increase_stock!(quantity)
end

# Low stock alert
variants_needing_restock = ProductVariant.low_stock(threshold: 5)
```

---

## 7. API STRUCTURE

### Endpoints

```ruby
# Product Variants
GET    /api/v1/products/:product_id/variants           # List variants
GET    /api/v1/products/:product_id/variants/:id       # Show variant
POST   /api/v1/products/:product_id/variants           # Create variant
PATCH  /api/v1/products/:product_id/variants/:id       # Update variant
DELETE /api/v1/products/:product_id/variants/:id       # Delete variant

# Bulk operations
POST   /api/v1/products/:product_id/variants/bulk_create    # Create multiple
PATCH  /api/v1/products/:product_id/variants/bulk_update    # Update stock
DELETE /api/v1/products/:product_id/variants/bulk_delete    # Delete multiple

# Stock management
PATCH  /api/v1/products/:product_id/variants/:id/adjust_stock
GET    /api/v1/products/:product_id/variants/low_stock

# Variant options
GET    /api/v1/products/:product_id/variant_options   # Available options
```

### Request/Response Examples

**Create Variant:**
```json
POST /api/v1/products/123/variants
{
  "variant": {
    "sku": "TSHIRT-RED-L",
    "barcode": "123456789",
    "stock_quantity": 50,
    "price_cents": 2500,
    "price_currency": "USD",
    "options": [
      { "name": "color", "value": "Red" },
      { "name": "size", "value": "Large" }
    ]
  }
}
```

**Response:**
```json
{
  "variant": {
    "id": "a1b2c3d4-...",
    "product_id": 123,
    "sku": "TSHIRT-RED-L",
    "variant_name": "Red / Large",
    "price": { "cents": 2500, "currency": "USD", "formatted": "$25.00" },
    "stock_quantity": 50,
    "available": true,
    "options": {
      "color": "Red",
      "size": "Large"
    },
    "created_at": "2026-02-26T10:00:00Z"
  }
}
```

**List Product with Variants:**
```json
GET /api/v1/products/123?include=variants

{
  "product": {
    "id": 123,
    "name": "Premium T-Shirt",
    "has_variants": true,
    "base_price": "$20.00",
    "variants_count": 12,
    "total_stock": 450,
    "variants": [
      {
        "id": "...",
        "sku": "TSHIRT-RED-S",
        "variant_name": "Red / Small",
        "price": "$20.00",
        "stock": 35
      },
      // ... more variants
    ],
    "variant_options": {
      "size": ["Small", "Medium", "Large", "XL"],
      "color": ["Red", "Blue", "Green"]
    }
  }
}
```

---

## 8. MIGRATION STRATEGY

### For Existing Products

**Option A: Automatic Migration (Recommended)**
```ruby
# Products without variants continue working as-is
# has_variants = false (default)
# Use existing product.quantity and product.daily_price

# Products with variants
# has_variants = true
# Ignore product.quantity, use variant stock
# Price from variant.price_cents or product.daily_price
```

**Option B: Convert Products to Single Variant**
```ruby
# For products that should have variants,
# create a "default" variant with current data
def convert_to_variants!
  return if has_variants?
  
  default_variant = product_variants.create!(
    sku: barcode || "DEFAULT-#{id}",
    stock_quantity: quantity,
    price_cents: daily_price_cents,
    price_currency: daily_price_currency,
    variant_name: "Default",
    active: true
  )
  
  update!(has_variants: true)
end
```

**Recommendation:** ✅ **Option A** - No migration needed, backward compatible

---

## 9. UI/UX CONSIDERATIONS

### Product Listing Page
```
T-Shirt
$20-$50 per day
12 variants available
[View Options]
```

### Product Detail Page
```
Premium T-Shirt
$20.00/day

Select Options:
┌─────────────────────────────┐
│ Color: ○ Red ○ Blue ○ Green │
│ Size:  ○ S   ○ M   ○ L  ○ XL│
└─────────────────────────────┘

Selected: Red / Large
Price: $25.00/day
Stock: 35 available
SKU: TSHIRT-RED-L

[Add to Booking]
```

### Booking Cart
```
Canon EOS R5                 $150/day x 2 days = $300
T-Shirt (Red/Large)          $25/day  x 1 day  = $25
```

---

## 10. PERFORMANCE CONSIDERATIONS

### Database Indexes

```ruby
add_index :product_variants, [:product_id, :active]
add_index :product_variants, [:company_id, :active]
add_index :product_variants, :sku, unique: true
add_index :product_variants, :barcode, unique: true, where: "barcode IS NOT NULL"
add_index :product_variants, [:product_id, :stock_quantity], where: "stock_quantity > 0"

add_index :variant_options, [:product_variant_id, :option_name], unique: true
add_index :variant_options, :option_name
```

### Query Optimization

```ruby
# Eager load variants with options
Product.includes(product_variants: :variant_options)

# Count variants efficiently
Product.left_joins(:product_variants)
  .select('products.*, COUNT(product_variants.id) as variants_count')
  .group('products.id')
```

---

## 11. TESTING STRATEGY

### Unit Tests
- Variant creation with options
- Price inheritance vs override
- Stock management (decrease/increase)
- Validation rules

### Integration Tests
- Creating product with variants
- Booking a specific variant
- Stock deduction on booking
- Returning variant restores stock

### Performance Tests
- Load 1000 products with 10 variants each
- Query response time < 100ms
- Variant availability check < 50ms

---

## 12. IMPLEMENTATION PHASES

### Phase 1: Core Models ✅ (Day 1)
- [ ] Create `product_variants` migration
- [ ] Create `variant_options` migration  
- [ ] Create `ProductVariant` model
- [ ] Create `VariantOption` model
- [ ] Update `Product` model associations
- [ ] Write model tests

### Phase 2: Stock Management ✅ (Day 1-2)
- [ ] Implement stock tracking methods
- [ ] Add stock adjustment endpoints
- [ ] Low stock alerts
- [ ] Inventory synchronization

### Phase 3: API Endpoints ✅ (Day 2)
- [ ] Variants CRUD controller
- [ ] Bulk operations
- [ ] Stock management endpoints
- [ ] API documentation

### Phase 4: Booking Integration ✅ (Day 2-3)
- [ ] Update BookingLineItem for variants
- [ ] Variant availability checks
- [ ] Stock deduction on booking
- [ ] Stock restoration on return/cancel

### Phase 5: Testing & Documentation ✅ (Day 3)
- [ ] Comprehensive test suite
- [ ] API documentation
- [ ] Migration guide
- [ ] Performance testing

---

## 13. POTENTIAL CHALLENGES & SOLUTIONS

### Challenge 1: Backward Compatibility
**Problem:** Existing products without variants should continue working  
**Solution:** Use `has_variants` flag. When false, use product-level inventory.

### Challenge 2: Complex Queries
**Problem:** Joining variants + options + product data is expensive  
**Solution:** Use database indexes, eager loading, and caching

### Challenge 3: Stock Synchronization
**Problem:** Concurrent bookings could oversell stock  
**Solution:** Database-level locking with `SELECT FOR UPDATE`

### Challenge 4: Bulk Variant Creation
**Problem:** Creating 50 variants (5 sizes × 10 colors) is tedious  
**Solution:** Bulk create API with option matrix

---

## 14. ALTERNATIVE APPROACHES CONSIDERED

### A. Flatten Structure (Rejected)
Make every variant a separate Product
- ❌ Loses product grouping
- ❌ Harder to show "12 colors available"
- ❌ Duplicate product descriptions

### B. EAV (Entity-Attribute-Value) (Rejected)
Store options in separate key-value tables
- ❌ Too complex
- ❌ Poor query performance
- ❌ Hard to maintain

### C. JSONB Only (Rejected)
Store all variants in product.variants JSONB
- ❌ No referential integrity
- ❌ Harder to query
- ❌ No bookable polymorphism

### ✅ Chosen: Normalized Tables with Separate ProductVariant
Best balance of flexibility, performance, and maintainability

---

## 15. SUCCESS CRITERIA

✅ **Functional Requirements Met:**
- [ ] Can create products with multiple variants
- [ ] Each variant has unique SKU
- [ ] Variants have independent inventory
- [ ] Variants can override pricing
- [ ] Bookings work with variants
- [ ] Stock updates automatically

✅ **Performance Requirements Met:**
- [ ] Product list with variants loads in < 200ms
- [ ] Variant creation < 100ms
- [ ] Stock check < 50ms
- [ ] Supports 10,000+ variants per company

✅ **Quality Requirements Met:**
- [ ] 90%+ test coverage
- [ ] API documentation complete
- [ ] Migration guide available
- [ ] Backward compatible

---

## 16. NEXT STEPS

**Before Implementation:**
1. ✅ Review this plan with stakeholders
2. ✅ Get approval on database schema
3. ✅ Confirm API contract
4. ✅ Review pricing strategy

**Implementation Order:**
1. Create migrations
2. Build models with validations
3. Write unit tests
4. Build API endpoints
5. Integration tests
6. Performance testing
7. Documentation

**Estimated Timeline:** 3-4 days for full implementation

---

## 17. OPEN QUESTIONS

1. **Image handling:** Should variant images replace or supplement product images?
2. **Pricing inheritance:** Should variants always inherit or always be independent?
3. **SKU generation:** Auto-generate SKUs or require manual input?
4. **Bulk operations:** Priority for bulk variant creation UI?
5. **Historical data:** Track variant stock history?

**Decision needed before proceeding!**

---

**Plan Status:** ✅ READY FOR REVIEW  
**Next:** Get approval, then start Phase 1 implementation
