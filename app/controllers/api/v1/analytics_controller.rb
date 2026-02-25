# app/controllers/api/v1/analytics_controller.rb
module Api
  module V1
    class AnalyticsController < ApplicationController
      # GET /api/v1/analytics/dashboard
      def dashboard
        render json: {
          revenue: revenue_stats,
          bookings: booking_stats,
          products: product_stats,
          clients: client_stats
        }
      end

      # GET /api/v1/analytics/revenue
      def revenue
        period = params[:period] || 'month' # day, week, month, year
        start_date, end_date = get_date_range(period)

        bookings = Booking.where(status: [:paid, :completed])
                          .where(created_at: start_date..end_date)

        total_revenue = bookings.sum(:total_price_cents)

        # Group by date
        revenue_by_date = bookings.group_by_day(:created_at, range: start_date..end_date)
                                  .sum(:total_price_cents)

        render json: {
          period: period,
          start_date: start_date,
          end_date: end_date,
          total_revenue: {
            cents: total_revenue,
            formatted: Money.new(total_revenue, 'USD').format
          },
          bookings_count: bookings.count,
          average_booking_value: {
            cents: bookings.count > 0 ? (total_revenue / bookings.count) : 0,
            formatted: Money.new(bookings.count > 0 ? (total_revenue / bookings.count) : 0, 'USD').format
          },
          revenue_by_date: revenue_by_date.transform_values { |cents|
            { cents: cents, formatted: Money.new(cents, 'USD').format }
          }
        }
      end

      # GET /api/v1/analytics/top_products
      def top_products
        limit = params[:limit]&.to_i || 10
        period = params[:period] || 'all_time'
        start_date, end_date = period == 'all_time' ? [nil, nil] : get_date_range(period)

        bookings_scope = Booking.where(status: [:confirmed, :paid, :completed])
        bookings_scope = bookings_scope.where(created_at: start_date..end_date) if start_date

        # Top by revenue
        top_by_revenue = BookingLineItem.joins(:booking)
                                        .where(bookings: { id: bookings_scope.select(:id) })
                                        .where(bookable_type: 'Product')
                                        .group(:bookable_id)
                                        .select('bookable_id, SUM(price_cents * quantity * days) as total_revenue, COUNT(*) as booking_count')
                                        .order('total_revenue DESC')
                                        .limit(limit)

        # Top by frequency
        top_by_frequency = BookingLineItem.joins(:booking)
                                          .where(bookings: { id: bookings_scope.select(:id) })
                                          .where(bookable_type: 'Product')
                                          .group(:bookable_id)
                                          .select('bookable_id, COUNT(*) as booking_count, SUM(quantity) as total_quantity')
                                          .order('booking_count DESC')
                                          .limit(limit)

        render json: {
          period: period,
          top_by_revenue: top_by_revenue.map { |item|
            product = Product.find(item.bookable_id)
            {
              id: product.id,
              name: product.name,
              category: product.category,
              total_revenue: {
                cents: item.total_revenue,
                formatted: Money.new(item.total_revenue, 'USD').format
              },
              booking_count: item.booking_count
            }
          },
          top_by_frequency: top_by_frequency.map { |item|
            product = Product.find(item.bookable_id)
            {
              id: product.id,
              name: product.name,
              category: product.category,
              booking_count: item.booking_count,
              total_quantity_rented: item.total_quantity
            }
          }
        }
      end

      # GET /api/v1/analytics/utilization
      def utilization
        start_date = params[:start_date] ? Date.parse(params[:start_date]) : 30.days.ago.to_date
        end_date = params[:end_date] ? Date.parse(params[:end_date]) : Date.today

        total_days = (end_date - start_date).to_i + 1
        products = Product.active

        utilization_data = products.map do |product|
          # Count days the product was booked
          booked_days = BookingLineItem.joins(:booking)
                                       .where(bookable: product)
                                       .where(bookings: { status: [:confirmed, :paid, :completed] })
                                       .where('bookings.start_date <= ? AND bookings.end_date >= ?', end_date, start_date)
                                       .sum do |line_item|
                                         booking = line_item.booking
                                         overlap_start = [booking.start_date.to_date, start_date].max
                                         overlap_end = [booking.end_date.to_date, end_date].min
                                         days = (overlap_end - overlap_start).to_i + 1
                                         days * line_item.quantity
                                       end

          max_possible_days = total_days * product.quantity
          utilization_rate = max_possible_days > 0 ? (booked_days.to_f / max_possible_days * 100).round(2) : 0

          {
            id: product.id,
            name: product.name,
            category: product.category,
            quantity: product.quantity,
            booked_days: booked_days,
            max_possible_days: max_possible_days,
            utilization_rate: utilization_rate,
            status: case utilization_rate
                    when 0...25 then 'underutilized'
                    when 25...60 then 'moderate'
                    when 60...85 then 'good'
                    else 'high_demand'
                    end
          }
        end

        # Sort by utilization rate
        utilization_data.sort_by! { |item| -item[:utilization_rate] }

        render json: {
          date_range: {
            start_date: start_date,
            end_date: end_date,
            total_days: total_days
          },
          overall_utilization: utilization_data.sum { |item| item[:utilization_rate] } / products.count.to_f,
          products: utilization_data
        }
      end

      # GET /api/v1/analytics/low_stock
      def low_stock
        threshold = params[:threshold]&.to_i || 2

        products = Product.active.where('quantity <= ?', threshold).order(:quantity)

        render json: {
          threshold: threshold,
          low_stock_products: products.map do |product|
            {
              id: product.id,
              name: product.name,
              category: product.category,
              current_quantity: product.quantity,
              active_bookings: product.booking_line_items.joins(:booking)
                                      .where(bookings: { status: [:confirmed, :paid] })
                                      .count
            }
          end
        }
      end

      # GET /api/v1/analytics/clients
      def clients
        limit = params[:limit]&.to_i || 10

        top_clients = Client.active
                           .joins(:bookings)
                           .where(bookings: { status: [:paid, :completed] })
                           .group('clients.id')
                           .select('clients.*, SUM(bookings.total_price_cents) as total_spent, COUNT(bookings.id) as booking_count')
                           .order('total_spent DESC')
                           .limit(limit)

        render json: {
          top_clients: top_clients.map do |client|
            {
              id: client.id,
              name: client.name,
              email: client.email,
              total_spent: {
                cents: client.total_spent,
                formatted: Money.new(client.total_spent, 'USD').format
              },
              booking_count: client.booking_count,
              average_booking_value: {
                cents: client.booking_count > 0 ? (client.total_spent / client.booking_count) : 0,
                formatted: Money.new(client.booking_count > 0 ? (client.total_spent / client.booking_count) : 0, 'USD').format
              }
            }
          end
        }
      end

      # GET /api/v1/analytics/booking_trends
      def booking_trends
        period = params[:period] || 'month'
        start_date, end_date = get_date_range(period)

        bookings = Booking.where(created_at: start_date..end_date)

        status_breakdown = bookings.group(:status).count
        bookings_by_date = bookings.group_by_day(:created_at, range: start_date..end_date).count

        render json: {
          period: period,
          date_range: { start_date: start_date, end_date: end_date },
          total_bookings: bookings.count,
          status_breakdown: status_breakdown,
          bookings_by_date: bookings_by_date,
          conversion_rate: calculate_conversion_rate(bookings),
          cancellation_rate: calculate_cancellation_rate(bookings)
        }
      end

      private

      def revenue_stats
        today = Date.today
        {
          today: Money.new(Booking.where(status: [:paid, :completed], created_at: today.beginning_of_day..today.end_of_day).sum(:total_price_cents), 'USD').format,
          this_week: Money.new(Booking.where(status: [:paid, :completed], created_at: today.beginning_of_week..today.end_of_week).sum(:total_price_cents), 'USD').format,
          this_month: Money.new(Booking.where(status: [:paid, :completed], created_at: today.beginning_of_month..today.end_of_month).sum(:total_price_cents), 'USD').format,
          all_time: Money.new(Booking.where(status: [:paid, :completed]).sum(:total_price_cents), 'USD').format
        }
      end

      def booking_stats
        {
          active: Booking.active.count,
          pending_payment: Booking.where(status: [:confirmed, :pending]).count,
          completed_today: Booking.where(status: :completed, updated_at: Date.today.beginning_of_day..Date.today.end_of_day).count,
          upcoming_pickups: Booking.where(status: [:confirmed, :paid]).where('start_date BETWEEN ? AND ?', Date.today, 3.days.from_now).count
        }
      end

      def product_stats
        {
          total_products: Product.active.count,
          low_stock: Product.active.where('quantity <= ?', 2).count,
          out_of_stock: Product.active.where(quantity: 0).count,
          categories: Product.active.group(:category).count
        }
      end

      def client_stats
        {
          total_clients: Client.active.count,
          new_this_month: Client.where(created_at: Date.today.beginning_of_month..Date.today.end_of_month).count,
          with_active_bookings: Client.joins(:bookings).where(bookings: { status: [:confirmed, :paid] }).distinct.count
        }
      end

      def get_date_range(period)
        case period
        when 'day', 'today'
          [Date.today.beginning_of_day, Date.today.end_of_day]
        when 'week'
          [Date.today.beginning_of_week, Date.today.end_of_week]
        when 'month'
          [Date.today.beginning_of_month, Date.today.end_of_month]
        when 'year'
          [Date.today.beginning_of_year, Date.today.end_of_year]
        when 'last_30_days'
          [30.days.ago, Time.current]
        else
          [Date.today.beginning_of_month, Date.today.end_of_month]
        end
      end

      def calculate_conversion_rate(bookings)
        total = bookings.count
        return 0 if total == 0

        converted = bookings.where(status: [:confirmed, :paid, :completed]).count
        ((converted.to_f / total) * 100).round(2)
      end

      def calculate_cancellation_rate(bookings)
        total = bookings.count
        return 0 if total == 0

        cancelled = bookings.where(status: :cancelled).count
        ((cancelled.to_f / total) * 100).round(2)
      end
    end
  end
end
