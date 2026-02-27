class ProductVariant < ApplicationRecord
  include ActsAsTenant

  # Multi-tenancy
  acts_as_tenant :company

  # Associations
  belongs_to :product
  belongs_to :company
  has_many :variant_options, dependent: :destroy
  has_many :variant_stock_histories, dependent: :destroy
  has_many :booking_line_items, as: :bookable, dependent: :restrict_with_error

  # Accept nested attributes for variant options
  accepts_nested_attributes_for :variant_options, allow_destroy: true

  # Monetization - price can override product price
  monetize :price_cents, allow_nil: true, with_model_currency: :price_currency
  monetize :compare_at_price_cents, allow_nil: true, with_model_currency: :price_currency

  # Validations
  validates :sku, presence: true, uniqueness: true
  validates :barcode, uniqueness: true, allow_blank: true
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :reserved_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :low_stock_threshold, numericality: { greater_than_or_equal_to: 0 }
  validates :position, numericality: { greater_than_or_equal_to: 0 }
  validates :weight, numericality: { greater_than: 0 }, allow_nil: true

  validate :reserved_quantity_cannot_exceed_stock

  # Callbacks
  before_validation :generate_sku, on: :create, if: -> { sku.blank? }
  before_validation :set_default_currency
  after_create :log_initial_stock
  after_update :log_stock_change, if: :saved_change_to_stock_quantity?

  # Scopes
  scope :active, -> { where(active: true, deleted: false) }
  scope :inactive, -> { where(active: false) }
  scope :in_stock, -> { where('stock_quantity > reserved_quantity') }
  scope :out_of_stock, -> { where('stock_quantity <= reserved_quantity') }
  scope :low_stock, -> { where('stock_quantity - reserved_quantity <= low_stock_threshold') }
  scope :featured, -> { where(featured: true) }
  scope :by_position, -> { order(position: :asc) }
  scope :not_deleted, -> { where(deleted: false) }

  # Search by variant options (e.g., find all "Red" variants)
  scope :with_option, ->(option_name, option_value) {
    joins(:variant_options)
      .where(variant_options: { option_name: option_name, option_value: option_value })
  }

  # Soft delete
  def soft_delete!
    update(deleted: true, deleted_at: Time.current, active: false)
  end

  def restore!
    update(deleted: false, deleted_at: nil, active: true)
  end

  # Stock management
  def available_quantity
    [stock_quantity - reserved_quantity, 0].max
  end

  def in_stock?
    available_quantity > 0
  end

  def out_of_stock?
    !in_stock?
  end

  def low_stock?
    available_quantity <= low_stock_threshold
  end

  def can_reserve?(quantity)
    available_quantity >= quantity
  end

  def reserve!(quantity, user: nil, booking: nil, reason: nil)
    raise ArgumentError, 'Quantity must be positive' if quantity <= 0
    raise StandardError, 'Insufficient stock' unless can_reserve?(quantity)

    transaction do
      update!(reserved_quantity: reserved_quantity + quantity)

      log_stock_history(
        change_type: 'reservation',
        quantity_change: 0, # Stock doesn't change, only reserved
        user: user,
        reference: booking,
        reason: reason || "Reserved #{quantity} units"
      )
    end
  end

  def release!(quantity, user: nil, booking: nil, reason: nil)
    raise ArgumentError, 'Quantity must be positive' if quantity <= 0
    raise StandardError, 'Cannot release more than reserved' if quantity > reserved_quantity

    transaction do
      update!(reserved_quantity: reserved_quantity - quantity)

      log_stock_history(
        change_type: 'release',
        quantity_change: 0, # Stock doesn't change, only reserved
        user: user,
        reference: booking,
        reason: reason || "Released #{quantity} units from reservation"
      )
    end
  end

  def adjust_stock!(new_quantity, user: nil, reason: nil)
    raise ArgumentError, 'Quantity cannot be negative' if new_quantity < 0

    old_quantity = stock_quantity
    quantity_change = new_quantity - old_quantity

    transaction do
      update!(stock_quantity: new_quantity)

      log_stock_history(
        change_type: 'adjustment',
        quantity_change: quantity_change,
        user: user,
        reason: reason || "Manual stock adjustment"
      )
    end
  end

  def restock!(quantity, user: nil, reason: nil)
    raise ArgumentError, 'Quantity must be positive' if quantity <= 0

    transaction do
      update!(stock_quantity: stock_quantity + quantity)

      log_stock_history(
        change_type: 'restock',
        quantity_change: quantity,
        user: user,
        reason: reason || "Restocked #{quantity} units"
      )
    end
  end

  def record_damage!(quantity, user: nil, reason: nil, metadata: {})
    raise ArgumentError, 'Quantity must be positive' if quantity <= 0
    raise StandardError, 'Cannot damage more than available stock' if quantity > stock_quantity

    transaction do
      update!(stock_quantity: stock_quantity - quantity)

      log_stock_history(
        change_type: 'damage',
        quantity_change: -quantity,
        user: user,
        reason: reason || "Damaged #{quantity} units",
        metadata: metadata
      )
    end
  end

  # Pricing
  def effective_price
    # Use variant price if set, otherwise fall back to product price
    price || product.daily_price
  end

  def has_discount?
    compare_at_price_cents.present? && compare_at_price_cents > price_cents.to_i
  end

  def discount_percentage
    return 0 unless has_discount?
    ((compare_at_price_cents - price_cents.to_i).to_f / compare_at_price_cents * 100).round(2)
  end

  # Display
  def display_name
    if variant_name.present?
      "#{product.name} - #{variant_name}"
    else
      option_string = variant_options.order(position: :asc).pluck(:option_value).join(' / ')
      "#{product.name} - #{option_string}"
    end
  end

  def option_hash
    variant_options.order(position: :asc).pluck(:option_name, :option_value).to_h
  end

  # For BookingLineItem compatibility (polymorphic bookable)
  def bookable_type
    'ProductVariant'
  end

  def rental_price(duration_days = 1)
    effective_price * duration_days
  end

  private

  def generate_sku
    # Auto-generate SKU: PRODUCT_SKU-VARIANT_NUMBER
    product_sku = product.barcode.presence || product.id.to_s
    variant_count = product.product_variants.count + 1
    self.sku = "#{product_sku}-V#{variant_count.to_s.rjust(3, '0')}"
  end

  def set_default_currency
    self.price_currency ||= product&.daily_price_currency || 'USD'
  end

  def reserved_quantity_cannot_exceed_stock
    if reserved_quantity > stock_quantity
      errors.add(:reserved_quantity, "cannot exceed stock quantity")
    end
  end

  def log_initial_stock
    return if stock_quantity.zero?

    log_stock_history(
      change_type: 'adjustment',
      quantity_change: stock_quantity,
      reason: 'Initial stock'
    )
  end

  def log_stock_change
    return unless saved_change_to_stock_quantity?

    old_quantity, new_quantity = saved_change_to_stock_quantity
    quantity_change = new_quantity - old_quantity

    log_stock_history(
      change_type: 'adjustment',
      quantity_change: quantity_change,
      reason: 'Stock updated'
    )
  end

  def log_stock_history(change_type:, quantity_change:, user: nil, reference: nil, reason: nil, metadata: {})
    variant_stock_histories.create!(
      company: company,
      user: user,
      change_type: change_type,
      quantity_before: stock_quantity - quantity_change,
      quantity_after: stock_quantity,
      quantity_change: quantity_change,
      reason: reason,
      reference_type: reference&.class&.name,
      reference_id: reference&.id,
      metadata: metadata
    )
  end
end
