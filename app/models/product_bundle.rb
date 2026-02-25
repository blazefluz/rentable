class ProductBundle < ApplicationRecord
  include ActsAsTenant

  # Audit trail
  has_paper_trail

  # Associations
  has_many :product_bundle_items, -> { order(position: :asc) }, dependent: :destroy
  has_many :products, through: :product_bundle_items

  # Nested attributes
  accepts_nested_attributes_for :product_bundle_items, allow_destroy: true

  # Enums
  enum :bundle_type, {
    must_rent_together: 0,    # All items MUST be rented together (enforced)
    suggested_bundle: 1,       # Suggested but not enforced
    cross_sell: 2,             # Cross-sell recommendation
    upsell: 3,                 # Upgrade/upsell recommendation
    frequently_together: 4     # Frequently rented together
  }, prefix: true

  # Validations
  validates :name, presence: true
  validates :discount_percentage, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }, allow_nil: true

  # Scopes
  scope :active, -> { where(active: true, deleted: false) }
  scope :enforced, -> { where(enforce_bundling: true) }
  scope :for_product, ->(product_id) {
    joins(:product_bundle_items).where(product_bundle_items: { product_id: product_id })
  }

  # Check if bundle can be fulfilled
  def available?(start_date, end_date, requested_qty = 1)
    return false if product_bundle_items.empty?

    product_bundle_items.where(required: true).all? do |item|
      required_qty = item.quantity * requested_qty
      item.product.available?(start_date, end_date, required_qty)
    end
  end

  # Get required products that are missing from a given list
  def missing_required_products(product_ids)
    required_product_ids = product_bundle_items.where(required: true).pluck(:product_id)
    required_product_ids - product_ids
  end

  # Check if a booking satisfies this bundle
  def satisfied_by_booking?(booking)
    booked_product_ids = booking.booking_line_items
      .where(bookable_type: 'Product')
      .pluck(:bookable_id)

    missing_required_products(booked_product_ids).empty?
  end

  # Calculate bundle discount for a set of products
  def calculate_bundle_discount(line_items)
    return 0 unless discount_percentage.present?

    total_price = line_items.sum(&:line_total_cents)
    (total_price * discount_percentage / 100.0).round
  end

  # Get all products that should be suggested when this bundle is triggered
  def suggested_products
    product_bundle_items.where(required: false).map(&:product)
  end

  # Get all required products
  def required_products
    product_bundle_items.where(required: true).map(&:product)
  end

  # Check if this bundle should be enforced
  def should_enforce?
    enforce_bundling && bundle_type_must_rent_together?
  end
end
