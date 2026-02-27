class TaxRate < ApplicationRecord
  include ActsAsTenant
  acts_as_tenant(:company)

  # Tenant association
  belongs_to :company, optional: true

  # Component relationships (for composite taxes)
  belongs_to :parent_tax_rate, class_name: 'TaxRate', optional: true
  has_many :component_tax_rates, class_name: 'TaxRate', foreign_key: :parent_tax_rate_id, dependent: :nullify

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

  enum :component_type, {
    composite: 0,      # Parent tax (sum of components)
    state_tax: 1,      # State-level tax
    county_tax: 2,     # County-level tax
    city_tax: 3,       # City-level tax
    district_tax: 4,   # Special district tax
    federal_tax: 5     # Federal tax
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
  scope :composite_rates, -> { where(component_type: :composite) }
  scope :component_rates, -> { where.not(component_type: :composite) }
  scope :top_level, -> { where(parent_tax_rate_id: nil) }

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

  # Check if this is a composite tax (parent with components)
  def composite?
    component_type_composite?
  end

  # Calculate total tax including all components
  def calculate_total_with_components(amount_cents, currency = 'USD')
    if composite? && component_tax_rates.any?
      # Sum all component taxes
      component_tax_rates.sum { |component| component.calculate_tax(amount_cents, currency) }
    else
      # Simple tax calculation
      calculate_tax(amount_cents, currency)
    end
  end

  # Get breakdown of all tax components
  def tax_breakdown(amount_cents, currency = 'USD')
    if composite? && component_tax_rates.any?
      components = component_tax_rates.map do |component|
        {
          name: component.name,
          type: component.component_type,
          rate: component.display_rate,
          amount_cents: component.calculate_tax(amount_cents, currency),
          amount: Money.new(component.calculate_tax(amount_cents, currency), currency)
        }
      end

      total_cents = components.sum { |c| c[:amount_cents] }

      {
        composite: true,
        total_cents: total_cents,
        total: Money.new(total_cents, currency),
        components: components
      }
    else
      # Simple tax - no breakdown needed
      tax_amount = calculate_tax(amount_cents, currency)
      {
        composite: false,
        total_cents: tax_amount,
        total: Money.new(tax_amount, currency),
        components: [
          {
            name: name,
            type: component_type,
            rate: display_rate,
            amount_cents: tax_amount,
            amount: Money.new(tax_amount, currency)
          }
        ]
      }
    end
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
