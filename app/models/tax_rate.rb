class TaxRate < ApplicationRecord
  include ActsAsTenant
  acts_as_tenant(:company)

  # Tenant association
  belongs_to :company, optional: true

  # Enums
  enum :tax_type, {
    sales_tax: 0,      # US state/local sales tax
    vat: 1,            # EU/UK VAT
    gst: 2,            # Canada/Australia GST
    hst: 3,            # Canada HST
    service_tax: 4,    # Service-specific tax
    luxury_tax: 5,     # High-value items
    environmental: 6   # Environmental fees
  }, prefix: true

  enum :calculation_method, {
    percentage: 0,     # % of subtotal
    flat_fee: 1,       # Fixed amount
    tiered: 2          # Based on price brackets
  }, prefix: true

  # Monetize
  monetize :rate_cents, allow_nil: true, with_model_currency: :rate_currency

  # Validations
  validates :name, presence: true
  validates :tax_code, presence: true, uniqueness: true
  validates :rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :country, presence: true
  validate :date_range_validity

  # Scopes
  scope :active, -> { where(active: true) }
  scope :current, -> {
    where('start_date <= ? AND (end_date IS NULL OR end_date >= ?)', Date.today, Date.today)
  }
  scope :by_country, ->(country) { where(country: country) }
  scope :by_state, ->(state) { where('state IS NULL OR state = ?', state) }
  scope :by_city, ->(city) { where('city IS NULL OR city = ?', city) }
  scope :ordered, -> { order(:position, :name) }

  # Class methods
  def self.for_location(country:, state: nil, city: nil, zip: nil)
    rates = active.current.by_country(country)
    rates = rates.by_state(state) if state.present?
    rates = rates.by_city(city) if city.present?

    if zip.present?
      rates = rates.where('zip_code_pattern IS NULL OR ? ~ zip_code_pattern', zip)
    end

    rates.ordered
  end

  # Calculate tax amount for given subtotal
  # Returns tax amount in cents (Integer)
  def calculate_tax(amount_cents, currency = 'USD')
    return 0 if amount_cents.nil? || amount_cents < minimum_amount_cents.to_i

    tax = case calculation_method
    when 'percentage'
      (amount_cents * rate).round.to_i
    when 'flat_fee'
      (rate_cents || 0).to_i
    when 'tiered'
      calculate_tiered_tax(amount_cents).to_i
    else
      0
    end

    # Apply maximum if set
    result = maximum_amount_cents.present? ? [tax, maximum_amount_cents].min : tax
    result.to_i  # Ensure we return an integer
  end

  def display_rate
    case calculation_method
    when 'percentage'
      formatted_rate = (rate * 100).round(2)
      # Remove trailing zeros and decimal point if not needed
      if formatted_rate % 1 == 0
        formatted_rate = formatted_rate.to_i
      end
      "#{formatted_rate}%"
    when 'flat_fee'
      Money.new((rate_cents || 0).to_i, 'USD').format
    else
      rate.to_s
    end
  end

  def display_name
    "#{name} (#{display_rate})"
  end

  def current?
    return false unless active?
    return false if start_date.present? && start_date > Date.today
    return false if end_date.present? && end_date < Date.today
    true
  end

  def expired?
    end_date.present? && end_date < Date.today
  end

  def upcoming?
    start_date.present? && start_date > Date.today
  end

  private

  def calculate_tiered_tax(amount_cents)
    # Placeholder for tiered tax calculation
    # Would need a separate tax_tiers table for full implementation
    (amount_cents * rate).round
  end

  def date_range_validity
    return if start_date.blank? || end_date.blank?

    if end_date < start_date
      errors.add(:end_date, 'must be after start date')
    end
  end

  def rate_currency
    'USD'
  end
end
