# frozen_string_literal: true

class ClientSegment < ApplicationRecord
  include ActsAsTenant

  # Associations
  belongs_to :company

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :filter_rules, presence: true
  validate :validate_filter_rules

  # Scopes
  scope :active_segments, -> { where(active: true) }
  scope :auto_updating, -> { where(auto_update: true) }
  scope :static, -> { where(auto_update: false) }

  # Instance methods
  def clients
    return Client.none unless company

    ActsAsTenant.with_tenant(company) do
      apply_filters(Client.all)
    end
  end

  def client_count
    clients.count
  end

  def refresh!
    # For static segments, we might want to cache the client IDs
    # For auto-updating segments, this recalculates the filters
    update!(updated_at: Time.current)
    client_count
  end

  def matches_client?(client)
    ActsAsTenant.with_tenant(company) do
      apply_filters(Client.where(id: client.id)).exists?
    end
  end

  def segment_metrics
    client_list = clients

    {
      total_clients: client_list.count,
      average_lifetime_value: calculate_average_ltv(client_list),
      total_bookings: client_list.sum(:total_rentals),
      total_revenue: calculate_total_revenue(client_list)
    }
  end

  private

  def validate_filter_rules
    return if filter_rules.blank?

    unless filter_rules.is_a?(Hash)
      errors.add(:filter_rules, 'must be a valid JSON object')
      return
    end

    # Validate filter rule structure
    allowed_keys = %w[lifetime_value booking_frequency last_booking_date product_category industry market_segment]
    invalid_keys = filter_rules.keys - allowed_keys
    if invalid_keys.any?
      errors.add(:filter_rules, "contains invalid filter keys: #{invalid_keys.join(', ')}")
    end
  end

  def apply_filters(scope)
    return scope if filter_rules.blank?

    filter_rules.each do |filter_type, filter_value|
      scope = apply_single_filter(scope, filter_type, filter_value)
    end

    scope
  end

  def apply_single_filter(scope, filter_type, filter_value)
    case filter_type
    when 'lifetime_value'
      apply_lifetime_value_filter(scope, filter_value)
    when 'booking_frequency'
      apply_booking_frequency_filter(scope, filter_value)
    when 'last_booking_date'
      apply_last_booking_date_filter(scope, filter_value)
    when 'product_category'
      apply_product_category_filter(scope, filter_value)
    when 'industry'
      apply_industry_filter(scope, filter_value)
    when 'market_segment'
      apply_market_segment_filter(scope, filter_value)
    else
      scope
    end
  end

  def apply_lifetime_value_filter(scope, filter_value)
    return scope if filter_value.blank?

    case filter_value
    when 'high' # > $10,000
      scope.where('lifetime_value_cents > ?', 1_000_000)
    when 'medium' # $5,000 - $10,000
      scope.where('lifetime_value_cents BETWEEN ? AND ?', 500_000, 1_000_000)
    when 'low' # < $5,000
      scope.where('lifetime_value_cents < ?', 500_000)
    when Hash
      min = filter_value['min']&.to_i || 0
      max = filter_value['max']&.to_i || Float::INFINITY
      scope.where('lifetime_value_cents BETWEEN ? AND ?', min * 100, max * 100)
    else
      scope
    end
  end

  def apply_booking_frequency_filter(scope, filter_value)
    return scope if filter_value.blank?

    case filter_value
    when 'monthly'
      scope.where('total_rentals >= ?', 12) # At least 1 booking per month over a year
    when 'quarterly'
      scope.where('total_rentals >= ? AND total_rentals < ?', 4, 12)
    when 'annual'
      scope.where('total_rentals >= ? AND total_rentals < ?', 1, 4)
    when 'one_time'
      scope.where(total_rentals: 1)
    else
      scope
    end
  end

  def apply_last_booking_date_filter(scope, filter_value)
    return scope if filter_value.blank?

    case filter_value
    when 'active' # Booked in last 30 days
      scope.where('last_rental_date >= ?', 30.days.ago)
    when 'dormant' # No booking in 90+ days
      scope.where('last_rental_date < ? OR last_rental_date IS NULL', 90.days.ago)
    when Hash
      days_ago = filter_value['days_ago']&.to_i
      if days_ago
        scope.where('last_rental_date >= ?', days_ago.days.ago)
      else
        scope
      end
    else
      scope
    end
  end

  def apply_product_category_filter(scope, filter_value)
    return scope if filter_value.blank?

    # This would require a join with bookings and products
    # Simplified version:
    scope.joins(:bookings)
         .joins('INNER JOIN booking_line_items ON booking_line_items.booking_id = bookings.id')
         .joins('INNER JOIN products ON booking_line_items.bookable_id = products.id AND booking_line_items.bookable_type = \'Product\'')
         .where('products.category = ?', filter_value)
         .distinct
  end

  def apply_industry_filter(scope, filter_value)
    return scope if filter_value.blank?

    scope.where(industry: filter_value)
  end

  def apply_market_segment_filter(scope, filter_value)
    return scope if filter_value.blank?

    scope.where(market_segment: filter_value)
  end

  def calculate_average_ltv(client_list)
    total = client_list.sum(:lifetime_value_cents)
    count = client_list.count
    return Money.new(0, company.currency || 'USD') if count.zero?

    Money.new(total / count, company.currency || 'USD')
  end

  def calculate_total_revenue(client_list)
    total = client_list.sum(:lifetime_value_cents)
    Money.new(total, company.currency || 'USD')
  end
end
