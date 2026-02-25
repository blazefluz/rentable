# app/services/availability_checker.rb
# Service to check product availability and prevent booking overlaps
# Inspired by AdamRMS clash prevention logic but built from scratch
class AvailabilityChecker
  attr_reader :product, :start_date, :end_date, :requested_quantity

  def initialize(product, start_date, end_date, requested_quantity = 1)
    @product = product
    @start_date = start_date
    @end_date = end_date
    @requested_quantity = requested_quantity
  end

  # Check if requested quantity is available for the date range
  def available?
    available_quantity >= requested_quantity
  end

  # Calculate available quantity considering overlapping bookings
  # Returns the minimum available quantity across all days in the range
  def available_quantity
    return product.quantity if product.quantity.zero?

    max_booked = max_concurrent_bookings
    product.quantity - max_booked
  end

  # Get detailed availability breakdown by date
  def availability_by_date
    return {} if start_date.nil? || end_date.nil?

    (start_date.to_date..end_date.to_date).map do |date|
      booked = booked_quantity_on_date(date)
      [date, {
        total: product.quantity,
        booked: booked,
        available: product.quantity - booked
      }]
    end.to_h
  end

  private

  # Find maximum concurrent bookings across the date range
  # This handles the case where different days have different booking levels
  def max_concurrent_bookings
    return 0 if start_date.nil? || end_date.nil?

    # Get all overlapping confirmed/paid bookings
    overlapping_bookings = product.booking_line_items
      .joins(:booking)
      .merge(Booking.confirmed_or_paid)
      .where("bookings.start_date < ? AND bookings.end_date > ?", end_date, start_date)

    return 0 if overlapping_bookings.empty?

    # Check each day in the requested range
    max_booked = 0
    (start_date.to_date..end_date.to_date).each do |date|
      daily_booked = booked_quantity_on_date(date, overlapping_bookings)
      max_booked = [max_booked, daily_booked].max
    end

    max_booked
  end

  # Calculate booked quantity on a specific date
  # Supports same-day return/pickup (end of day1 == start of day2 = no overlap)
  def booked_quantity_on_date(date, bookings_scope = nil)
    bookings_scope ||= product.booking_line_items
      .joins(:booking)
      .merge(Booking.confirmed_or_paid)

    # A booking occupies a date if: start_date <= date < end_date
    # This allows same-day return/pickup (end time of one booking = start of next)
    bookings_scope
      .where("bookings.start_date <= ? AND bookings.end_date > ?",
             date.end_of_day, date.beginning_of_day)
      .sum(:quantity)
  end
end
