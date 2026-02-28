# Service for analyzing revenue by various dimensions
module Financial
  class RevenueAnalysis
    attr_reader :company

    def initialize(company:)
      @company = company
    end

    # Revenue breakdown by product category
    def by_category(start_date, end_date)
      results = BookingLineItem.joins(:booking, :bookable)
                                .where(bookings: { company_id: company.id })
                                .where('bookings.start_date >= ? AND bookings.start_date <= ?', start_date, end_date)
                                .where(bookable_type: 'Product')
                                .joins("INNER JOIN products ON products.id = booking_line_items.bookable_id")
                                .group('products.category')
                                .sum(:line_total_cents)

      total_revenue = results.values.sum

      categories = results.map do |category, revenue_cents|
        {
          name: category || 'Uncategorized',
          revenue: revenue_cents,
          revenue_formatted: Money.new(revenue_cents, 'USD').format,
          percentage: total_revenue.zero? ? 0 : (revenue_cents.to_f / total_revenue * 100).round(2)
        }
      end.sort_by { |c| -c[:revenue] }

      {
        categories: categories,
        total_revenue: total_revenue,
        total_revenue_formatted: Money.new(total_revenue, 'USD').format,
        period: { start_date: start_date, end_date: end_date }
      }
    end

    # Revenue breakdown by client
    def by_client(start_date, end_date, limit: 10)
      results = Booking.where(company: company)
                       .where('start_date >= ? AND start_date <= ?', start_date, end_date)
                       .joins(:client)
                       .group('clients.id', 'clients.name')
                       .select('clients.id as client_id, clients.name as client_name, SUM(bookings.total_price_cents) as revenue_cents, COUNT(bookings.id) as booking_count')
                       .order('revenue_cents DESC')
                       .limit(limit)

      total_revenue = Booking.where(company: company)
                             .where('start_date >= ? AND start_date <= ?', start_date, end_date)
                             .sum(:total_price_cents)

      clients = results.map do |result|
        {
          client_id: result.client_id,
          client_name: result.client_name,
          revenue: result.revenue_cents,
          revenue_formatted: Money.new(result.revenue_cents, 'USD').format,
          booking_count: result.booking_count,
          percentage: total_revenue.zero? ? 0 : (result.revenue_cents.to_f / total_revenue * 100).round(2),
          average_booking_value: (result.revenue_cents.to_f / result.booking_count).round(0),
          average_booking_value_formatted: Money.new(result.revenue_cents / result.booking_count, 'USD').format
        }
      end

      {
        clients: clients,
        total_revenue: total_revenue,
        total_revenue_formatted: Money.new(total_revenue, 'USD').format,
        period: { start_date: start_date, end_date: end_date }
      }
    end

    # Revenue breakdown by product
    def by_product(start_date, end_date, limit: 20)
      results = BookingLineItem.joins(:booking)
                                .where(bookings: { company_id: company.id })
                                .where('bookings.start_date >= ? AND bookings.start_date <= ?', start_date, end_date)
                                .where(bookable_type: 'Product')
                                .joins("INNER JOIN products ON products.id = booking_line_items.bookable_id")
                                .group('products.id', 'products.name')
                                .select('products.id as product_id, products.name as product_name, SUM(booking_line_items.line_total_cents) as revenue_cents, SUM(booking_line_items.quantity) as quantity_rented, COUNT(DISTINCT bookings.id) as booking_count')
                                .order('revenue_cents DESC')
                                .limit(limit)

      total_revenue = BookingLineItem.joins(:booking)
                                     .where(bookings: { company_id: company.id })
                                     .where('bookings.start_date >= ? AND bookings.start_date <= ?', start_date, end_date)
                                     .sum(:line_total_cents)

      products = results.map do |result|
        {
          product_id: result.product_id,
          product_name: result.product_name,
          revenue: result.revenue_cents,
          revenue_formatted: Money.new(result.revenue_cents, 'USD').format,
          quantity_rented: result.quantity_rented,
          booking_count: result.booking_count,
          percentage: total_revenue.zero? ? 0 : (result.revenue_cents.to_f / total_revenue * 100).round(2)
        }
      end

      {
        products: products,
        total_revenue: total_revenue,
        total_revenue_formatted: Money.new(total_revenue, 'USD').format,
        period: { start_date: start_date, end_date: end_date }
      }
    end

    # Monthly revenue breakdown for a year
    def by_month(year)
      start_date = Date.new(year, 1, 1)
      end_date = Date.new(year, 12, 31)

      months = (1..12).map do |month|
        month_start = Date.new(year, month, 1)
        month_end = month_start.end_of_month

        revenue = Booking.where(company: company)
                         .where('start_date >= ? AND start_date <= ?', month_start, month_end)
                         .sum(:total_price_cents)

        {
          month: month,
          month_name: Date::MONTHNAMES[month],
          revenue: revenue,
          revenue_formatted: Money.new(revenue, 'USD').format,
          start_date: month_start,
          end_date: month_end
        }
      end

      total_revenue = months.sum { |m| m[:revenue] }
      average_revenue = total_revenue / 12.0

      {
        year: year,
        months: months,
        total_revenue: total_revenue,
        total_revenue_formatted: Money.new(total_revenue, 'USD').format,
        average_monthly_revenue: average_revenue.round(0),
        average_monthly_revenue_formatted: Money.new(average_revenue, 'USD').format
      }
    end

    # Growth trend over last N months
    def growth_trend(months: 12)
      results = []
      current_month = Date.current.beginning_of_month

      months.times do |i|
        month_start = (current_month - i.months).beginning_of_month
        month_end = month_start.end_of_month

        revenue = Booking.where(company: company)
                         .where('start_date >= ? AND start_date <= ?', month_start, month_end)
                         .sum(:total_price_cents)

        results.unshift({
          month: month_start.strftime('%B %Y'),
          revenue: revenue,
          revenue_formatted: Money.new(revenue, 'USD').format,
          start_date: month_start,
          end_date: month_end
        })
      end

      # Calculate month-over-month growth
      results.each_with_index do |month_data, index|
        if index > 0
          previous_revenue = results[index - 1][:revenue]
          if previous_revenue.zero?
            month_data[:growth_percentage] = 0
          else
            growth = ((month_data[:revenue] - previous_revenue).to_f / previous_revenue * 100).round(2)
            month_data[:growth_percentage] = growth
          end
        else
          month_data[:growth_percentage] = nil
        end
      end

      {
        months: results,
        period: "#{results.first[:month]} - #{results.last[:month]}"
      }
    end

    # Revenue by client industry
    def by_industry(start_date, end_date)
      results = Booking.where(company: company)
                       .where('start_date >= ? AND start_date <= ?', start_date, end_date)
                       .joins(:client)
                       .where.not(clients: { industry: nil })
                       .group('clients.industry')
                       .sum(:total_price_cents)

      total_revenue = results.values.sum

      industries = results.map do |industry, revenue_cents|
        {
          name: industry,
          revenue: revenue_cents,
          revenue_formatted: Money.new(revenue_cents, 'USD').format,
          percentage: total_revenue.zero? ? 0 : (revenue_cents.to_f / total_revenue * 100).round(2)
        }
      end.sort_by { |i| -i[:revenue] }

      {
        industries: industries,
        total_revenue: total_revenue,
        total_revenue_formatted: Money.new(total_revenue, 'USD').format,
        period: { start_date: start_date, end_date: end_date }
      }
    end

    # Revenue by location (if multi-location)
    def by_location(start_date, end_date)
      results = Booking.where(company: company)
                       .where('start_date >= ? AND start_date <= ?', start_date, end_date)
                       .joins(:venue_location)
                       .group('locations.id', 'locations.name')
                       .select('locations.id as location_id, locations.name as location_name, SUM(bookings.total_price_cents) as revenue_cents')
                       .order('revenue_cents DESC')

      total_revenue = results.sum(&:revenue_cents)

      locations = results.map do |result|
        {
          location_id: result.location_id,
          location_name: result.location_name,
          revenue: result.revenue_cents,
          revenue_formatted: Money.new(result.revenue_cents, 'USD').format,
          percentage: total_revenue.zero? ? 0 : (result.revenue_cents.to_f / total_revenue * 100).round(2)
        }
      end

      {
        locations: locations,
        total_revenue: total_revenue,
        total_revenue_formatted: Money.new(total_revenue, 'USD').format,
        period: { start_date: start_date, end_date: end_date }
      }
    end
  end
end
