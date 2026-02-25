# app/controllers/api/v1/calendar_controller.rb
module Api
  module V1
    class CalendarController < ApplicationController
      # GET /api/v1/calendar/month?year=2026&month=2
      def month
        year = params[:year]&.to_i || Date.today.year
        month = params[:month]&.to_i || Date.today.month

        start_date = Date.new(year, month, 1)
        end_date = start_date.end_of_month

        # Get all bookings for the month
        bookings = Booking.where(status: [:confirmed, :paid, :completed])
                         .where('start_date <= ? AND end_date >= ?', end_date, start_date)
                         .includes(booking_line_items: :bookable)

        # Build calendar grid
        calendar_data = (start_date..end_date).map do |date|
          day_bookings = bookings.select do |booking|
            booking.start_date.to_date <= date && booking.end_date.to_date >= date
          end

          {
            date: date,
            day_name: date.strftime('%A'),
            bookings_count: day_bookings.count,
            total_items: day_bookings.sum { |b| b.booking_line_items.sum(:quantity) },
            bookings: day_bookings.map { |b| booking_summary(b) }
          }
        end

        render json: {
          year: year,
          month: month,
          month_name: start_date.strftime('%B'),
          start_date: start_date,
          end_date: end_date,
          total_bookings: bookings.count,
          calendar: calendar_data
        }
      end

      # GET /api/v1/calendar/week?date=2026-02-25
      def week
        reference_date = params[:date] ? Date.parse(params[:date]) : Date.today
        start_date = reference_date.beginning_of_week
        end_date = reference_date.end_of_week

        bookings = Booking.where(status: [:confirmed, :paid, :completed])
                         .where('start_date <= ? AND end_date >= ?', end_date, start_date)
                         .includes(booking_line_items: :bookable)

        # Build week grid
        week_data = (start_date..end_date).map do |date|
          day_bookings = bookings.select do |booking|
            booking.start_date.to_date <= date && booking.end_date.to_date >= date
          end

          {
            date: date,
            day_name: date.strftime('%A'),
            is_today: date == Date.today,
            bookings_count: day_bookings.count,
            bookings: day_bookings.map { |b| booking_detail(b) }
          }
        end

        render json: {
          week_start: start_date,
          week_end: end_date,
          calendar: week_data
        }
      end

      # GET /api/v1/calendar/product_availability?product_id=1&year=2026&month=2
      def product_availability
        product = Product.find(params[:product_id])
        year = params[:year]&.to_i || Date.today.year
        month = params[:month]&.to_i || Date.today.month

        start_date = Date.new(year, month, 1)
        end_date = start_date.end_of_month

        # Get availability for each day
        availability_grid = (start_date..end_date).map do |date|
          checker = AvailabilityChecker.new(product, date, date)

          {
            date: date,
            total_quantity: product.quantity,
            available: checker.available_quantity,
            booked: product.quantity - checker.available_quantity,
            percentage_available: ((checker.available_quantity.to_f / product.quantity) * 100).round(2)
          }
        end

        render json: {
          product: {
            id: product.id,
            name: product.name,
            total_quantity: product.quantity
          },
          year: year,
          month: month,
          availability: availability_grid
        }
      end

      # GET /api/v1/calendar/timeline?start_date=2026-02-01&end_date=2026-02-29
      def timeline
        start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today
        end_date = params[:end_date] ? Date.parse(params[:end_date]) : start_date + 30.days

        bookings = Booking.where(status: [:confirmed, :paid, :completed])
                         .where('start_date <= ? AND end_date >= ?', end_date, start_date)
                         .includes(:client, booking_line_items: :bookable)
                         .order(:start_date)

        timeline_data = bookings.map do |booking|
          {
            id: booking.id,
            reference_number: booking.reference_number,
            client: booking.client ? booking.client.name : booking.customer_name,
            start_date: booking.start_date,
            end_date: booking.end_date,
            duration_days: booking.rental_days,
            status: booking.status,
            total_price: booking.total_price.format,
            items: booking.booking_line_items.map do |item|
              {
                type: item.bookable_type,
                name: item.bookable.name,
                quantity: item.quantity
              }
            end
          }
        end

        render json: {
          date_range: {
            start: start_date,
            end: end_date
          },
          total_bookings: timeline_data.count,
          timeline: timeline_data
        }
      end

      private

      def booking_summary(booking)
        {
          id: booking.id,
          reference: booking.reference_number,
          customer: booking.customer_name,
          status: booking.status
        }
      end

      def booking_detail(booking)
        {
          id: booking.id,
          reference_number: booking.reference_number,
          customer: booking.customer_name,
          client: booking.client ? { id: booking.client.id, name: booking.client.name } : nil,
          start_date: booking.start_date,
          end_date: booking.end_date,
          status: booking.status,
          total_price: booking.total_price.format,
          items_count: booking.booking_line_items.count
        }
      end
    end
  end
end
