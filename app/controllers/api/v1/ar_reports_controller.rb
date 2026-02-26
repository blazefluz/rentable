# app/controllers/api/v1/ar_reports_controller.rb
class Api::V1::ArReportsController < ApplicationController
  # GET /api/v1/ar_reports/aging
  # Full AR aging report with breakdown by bucket
  def aging
    currency = params[:currency] || 'USD'
    aging_data = Booking.ar_aging_summary(currency: currency)

    render json: {
      report_date: Date.today,
      currency: currency,
      aging_buckets: {
        current: format_aging_bucket(aging_data[:current], 1.0),
        days_0_30: format_aging_bucket(aging_data[:days_0_30], 0.90),
        days_31_60: format_aging_bucket(aging_data[:days_31_60], 0.75),
        days_61_90: format_aging_bucket(aging_data[:days_61_90], 0.60),
        days_90_plus: format_aging_bucket(aging_data[:days_90_plus], 0.25)
      },
      total: {
        count: aging_data[:total][:count],
        balance: aging_data[:total][:balance].format,
        balance_cents: aging_data[:total][:balance].cents
      }
    }
  end

  # GET /api/v1/ar_reports/summary
  # Quick summary of AR health
  def summary
    currency = params[:currency] || 'USD'

    total_ar = Booking.with_balance_due.sum('total_price_cents - (SELECT COALESCE(SUM(amount_cents), 0) FROM payments WHERE booking_id = bookings.id AND payment_type = 1)')
    overdue_count = Booking.overdue.count
    overdue_amount = Booking.overdue.sum('total_price_cents - (SELECT COALESCE(SUM(amount_cents), 0) FROM payments WHERE booking_id = bookings.id AND payment_type = 1)')

    render json: {
      total_receivables: Money.new(total_ar, currency).format,
      total_receivables_cents: total_ar,
      overdue_count: overdue_count,
      overdue_amount: Money.new(overdue_amount, currency).format,
      overdue_amount_cents: overdue_amount,
      collection_statuses: collection_status_summary,
      days_sales_outstanding: calculate_dso
    }
  end

  # GET /api/v1/ar_reports/by_client
  # AR breakdown by client
  def by_client
    currency = params[:currency] || 'USD'
    limit = params[:limit]&.to_i || 50

    clients = Client.joins(:bookings)
                   .merge(Booking.with_balance_due)
                   .select(
                     'clients.*',
                     'COUNT(DISTINCT bookings.id) as outstanding_bookings_count',
                     'SUM(bookings.total_price_cents - (SELECT COALESCE(SUM(amount_cents), 0) FROM payments WHERE booking_id = bookings.id AND payment_type = 1)) as total_balance_cents'
                   )
                   .group('clients.id')
                   .order('total_balance_cents DESC')
                   .limit(limit)

    render json: {
      clients: clients.map { |client| format_client_ar(client, currency) }
    }
  end

  # GET /api/v1/ar_reports/overdue_list
  # List of all overdue bookings
  def overdue_list
    bookings = Booking.overdue
                     .includes(:client, :venue_location)
                     .order(days_past_due: :desc)

    bookings = bookings.where(client_id: params[:client_id]) if params[:client_id].present?
    bookings = bookings.where(collection_status: params[:collection_status]) if params[:collection_status].present?
    bookings = bookings.where(aging_bucket: params[:aging_bucket]) if params[:aging_bucket].present?

    render json: {
      overdue_bookings: bookings.map { |booking| format_overdue_booking(booking) },
      total_count: bookings.count,
      total_balance_due: Money.new(bookings.sum(&:balance_due), 'USD').format
    }
  end

  private

  def format_aging_bucket(data, collection_rate)
    {
      count: data[:count],
      balance: data[:balance].format,
      balance_cents: data[:balance].cents,
      collection_rate: "#{(collection_rate * 100).round}%",
      expected_collectible: (data[:balance] * collection_rate).format
    }
  end

  def collection_status_summary
    {
      current: Booking.where(collection_status: :current_status).with_balance_due.count,
      reminder_sent: Booking.where(collection_status: :reminder_sent).count,
      first_notice: Booking.where(collection_status: :first_notice).count,
      second_notice: Booking.where(collection_status: :second_notice).count,
      final_notice: Booking.where(collection_status: :final_notice).count,
      in_collections: Booking.where(collection_status: :in_collections).count,
      payment_plan: Booking.where(collection_status: :payment_plan).count,
      written_off: Booking.where(collection_status: :written_off).count
    }
  end

  def format_client_ar(client, currency)
    {
      id: client.id,
      name: client.name,
      email: client.email,
      outstanding_bookings: client.outstanding_bookings_count,
      total_balance: Money.new(client.total_balance_cents, currency).format,
      total_balance_cents: client.total_balance_cents,
      credit_status: client.credit_status,
      credit_limit: client.credit_limit&.format,
      available_credit: client.available_credit&.format
    }
  end

  def format_overdue_booking(booking)
    {
      id: booking.id,
      reference_number: booking.reference_number,
      client: {
        id: booking.client&.id,
        name: booking.client&.name || booking.customer_name,
        email: booking.client&.email || booking.customer_email
      },
      start_date: booking.start_date,
      end_date: booking.end_date,
      payment_due_date: booking.payment_due_date,
      days_past_due: booking.days_past_due,
      aging_bucket: booking.aging_bucket,
      total_price: booking.total_price.format,
      total_paid: Money.new(booking.total_payments_received, booking.total_price_currency).format,
      balance_due: Money.new(booking.balance_due, booking.total_price_currency).format,
      balance_due_cents: booking.balance_due,
      collection_status: booking.collection_status,
      payment_reminder_count: booking.payment_reminder_count,
      last_reminder_sent: booking.last_payment_reminder_sent_at,
      expected_collection_rate: "#{(booking.expected_collection_rate * 100).round}%",
      expected_collectible: booking.expected_collectible_amount.format
    }
  end

  def calculate_dso
    total_ar = Booking.with_balance_due.sum('total_price_cents - (SELECT COALESCE(SUM(amount_cents), 0) FROM payments WHERE booking_id = bookings.id AND payment_type = 1)')
    sales_90_days = Booking.where('created_at >= ?', 90.days.ago)
                          .where(status: [:confirmed, :paid, :completed])
                          .sum(:total_price_cents)

    return 0 if sales_90_days.zero?
    (total_ar.to_f / sales_90_days * 90).round(1)
  end
end
