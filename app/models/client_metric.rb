class ClientMetric < ApplicationRecord
  belongs_to :client

  # Money fields
  monetize :revenue_cents, allow_nil: true

  # Validations
  validates :metric_date, presence: true, uniqueness: { scope: :client_id }
  validates :rentals_count, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :items_rented, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  validates :utilization_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_blank: true
  validates :average_rental_duration, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true

  # Scopes
  scope :for_date, ->(date) { where(metric_date: date) }
  scope :for_month, ->(date) { where(metric_date: date.beginning_of_month..date.end_of_month) }
  scope :for_year, ->(year) { where('EXTRACT(YEAR FROM metric_date) = ?', year) }
  scope :recent, -> { order(metric_date: :desc) }
  scope :chronological, -> { order(metric_date: :asc) }

  # Class methods
  def self.calculate_for_client(client, date = Date.yesterday)
    bookings = client.bookings.where(
      'DATE(start_date) <= ? AND DATE(end_date) >= ?',
      date, date
    )

    metric = find_or_initialize_by(client: client, metric_date: date)
    metric.assign_attributes(
      rentals_count: bookings.count,
      revenue_cents: bookings.sum(:total_price_cents),
      revenue_currency: 'USD',
      items_rented: bookings.joins(:booking_line_items).sum('booking_line_items.quantity'),
      average_rental_duration: bookings.average('EXTRACT(DAY FROM (end_date - start_date))').to_f.round(2)
    )
    metric.save!
    metric
  end

  def self.aggregate_for_period(client, start_date, end_date)
    metrics = where(client: client, metric_date: start_date..end_date)

    {
      total_rentals: metrics.sum(:rentals_count),
      total_revenue: Money.new(metrics.sum(:revenue_cents), 'USD'),
      total_items: metrics.sum(:items_rented),
      average_utilization: metrics.average(:utilization_rate).to_f.round(2),
      average_duration: metrics.average(:average_rental_duration).to_f.round(2)
    }
  end

  # Instance methods
  def formatted_date
    metric_date.strftime('%B %d, %Y')
  end

  def performance_indicator
    return 'neutral' unless rentals_count && revenue_cents

    if rentals_count > 5 && revenue_cents > 50_000
      'excellent'
    elsif rentals_count > 2 && revenue_cents > 20_000
      'good'
    elsif rentals_count > 0
      'fair'
    else
      'poor'
    end
  end
end
