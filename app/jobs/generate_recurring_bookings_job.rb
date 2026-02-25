class GenerateRecurringBookingsJob < ApplicationJob
  queue_as :default

  def perform
    # Find all active recurring bookings that need generation
    recurring_bookings = RecurringBooking.active
      .where('next_occurrence <= ?', Time.current)
      .where('end_date IS NULL OR end_date >= ?', Time.current)

    generated_count = 0
    failed_count = 0

    recurring_bookings.find_each do |recurring_booking|
      begin
        # Check if max occurrences reached
        if recurring_booking.max_occurrences.present? &&
           recurring_booking.occurrence_count >= recurring_booking.max_occurrences
          recurring_booking.complete!
          Rails.logger.info "Completed RecurringBooking ##{recurring_booking.id} - max occurrences reached"
          next
        end

        # Generate the next booking
        booking = recurring_booking.generate_next_booking!
        generated_count += 1

        Rails.logger.info "Generated Booking ##{booking.id} from RecurringBooking ##{recurring_booking.id}"

        # Send notification if configured
        if recurring_booking.notify_on_generation
          BookingMailer.recurring_booking_created(booking).deliver_later
        end
      rescue => e
        failed_count += 1
        Rails.logger.error "Failed to generate booking from RecurringBooking ##{recurring_booking.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end

    Rails.logger.info "GenerateRecurringBookingsJob completed: #{generated_count} bookings generated, #{failed_count} failed"
  end
end
