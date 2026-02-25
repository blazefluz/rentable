class ProductMetric < ApplicationRecord
  include ActsAsTenant

  # Audit trail
  has_paper_trail

  # Associations
  belongs_to :product

  # Monetize
  monetize :revenue_cents, as: :revenue, with_model_currency: :revenue_currency, allow_nil: true

  # Validations
  validates :metric_date, presence: true
  validates :utilization_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  # Scopes
  scope :for_date_range, ->(start_date, end_date) { where(metric_date: start_date..end_date) }
  scope :for_month, ->(date) { where(metric_date: date.beginning_of_month..date.end_of_month) }
  scope :for_year, ->(date) { where(metric_date: date.beginning_of_year..date.end_of_year) }
  scope :recent, -> { order(metric_date: :desc) }

  # Calculate metrics for a product on a specific date
  def self.calculate_for_product(product, date = Date.today)
    start_of_period = date.beginning_of_month
    end_of_period = date.end_of_month
    total_days = (end_of_period - start_of_period).to_i + 1

    # Get bookings for this period
    bookings = product.booking_line_items
      .joins(:booking)
      .where("bookings.start_date <= ? AND bookings.end_date >= ?", end_of_period, start_of_period)
      .where("bookings.status != ?", Booking.statuses[:cancelled])

    rental_days = 0
    revenue = 0

    bookings.each do |line_item|
      booking = line_item.booking
      # Calculate overlap days
      overlap_start = [booking.start_date, start_of_period].max
      overlap_end = [booking.end_date, end_of_period].min
      days = (overlap_end - overlap_start).to_i + 1
      rental_days += days * line_item.quantity
      revenue += line_item.line_total.cents if line_item.line_total
    end

    idle_days = total_days - (rental_days / [product.quantity, 1].max)
    utilization_rate = (rental_days.to_f / (total_days * product.quantity) * 100).round(2)

    find_or_initialize_by(product: product, metric_date: date).tap do |metric|
      metric.rental_days = rental_days
      metric.idle_days = [idle_days, 0].max
      metric.revenue_cents = revenue
      metric.revenue_currency = product.daily_price_currency
      metric.utilization_rate = utilization_rate
      metric.times_rented = bookings.count
      metric.save
    end
  end

  # Calculate average utilization rate
  def self.average_utilization(product, start_date, end_date)
    metrics = where(product: product, metric_date: start_date..end_date)
    return 0 if metrics.empty?
    metrics.average(:utilization_rate).to_f.round(2)
  end

  # Calculate total revenue
  def self.total_revenue(product, start_date, end_date)
    where(product: product, metric_date: start_date..end_date).sum(:revenue_cents)
  end
end
