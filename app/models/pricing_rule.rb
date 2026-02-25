class PricingRule < ApplicationRecord
  include ActsAsTenant

  # Audit trail
  has_paper_trail

  # Associations
  belongs_to :product, optional: true
  belongs_to :product_type, optional: true

  # Enums
  enum :rule_type, {
    seasonal: 0,          # Date-based pricing (holidays, peak season)
    volume_discount: 1,   # Multi-week/multi-day discounts
    weekend_rate: 2,      # Special weekend pricing
    day_of_week: 3,       # Specific day pricing
    early_bird: 4,        # Book early discount
    last_minute: 5        # Last minute discount
  }, prefix: true

  enum :day_of_week, {
    monday: 0,
    tuesday: 1,
    wednesday: 2,
    thursday: 3,
    friday: 4,
    saturday: 5,
    sunday: 6
  }, prefix: true, suffix: true

  # Monetize
  monetize :price_override_cents, as: :price_override, with_model_currency: :price_override_currency, allow_nil: true

  # Validations
  validates :name, presence: true
  validates :rule_type, presence: true
  validates :priority, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :has_product_or_product_type
  validate :valid_date_range

  # Scopes
  scope :active, -> { where(active: true, deleted: false) }
  scope :for_product, ->(product_id) { where(product_id: product_id) }
  scope :for_product_type, ->(type_id) { where(product_type_id: type_id) }
  scope :by_priority, -> { order(priority: :desc) }
  scope :applicable_on, ->(date) {
    where('(start_date IS NULL OR start_date <= ?) AND (end_date IS NULL OR end_date >= ?)', date, date)
  }

  # Check if rule applies to a given date range
  def applies_to?(start_date, end_date, rental_days)
    return false unless active? && !deleted?

    # Check date range
    if start_date.present? && end_date.present?
      return false if self.start_date.present? && self.start_date > end_date
      return false if self.end_date.present? && self.end_date < start_date
    end

    # Check rental duration
    if rental_days.present?
      return false if min_days.present? && rental_days < min_days
      return false if max_days.present? && rental_days > max_days
    end

    true
  end

  # Calculate price adjustment
  def calculate_price(base_price, rental_days = nil)
    return base_price if price_override_cents.present?
    return base_price * (1 - discount_percentage / 100.0) if discount_percentage.present?
    base_price
  end

  private

  def has_product_or_product_type
    if product_id.blank? && product_type_id.blank?
      errors.add(:base, 'Must have either a product or product type')
    end
  end

  def valid_date_range
    return if start_date.blank? || end_date.blank?

    if end_date < start_date
      errors.add(:end_date, 'must be after start date')
    end
  end
end
