# app/jobs/send_booking_reminders_job.rb
class SendBookingRemindersJob < ApplicationJob
  queue_as :default

  # Run this job daily to send reminders for upcoming bookings
  def perform
    # Find bookings starting in 2 days
    upcoming_bookings = Booking.confirmed_or_paid
                              .where(start_date: 2.days.from_now.beginning_of_day..2.days.from_now.end_of_day)
                              .where.not(deleted: true)

    sent_count = 0

    upcoming_bookings.find_each do |booking|
      begin
        BookingMailer.reminder(booking).deliver_now
        sent_count += 1
        Rails.logger.info "Sent reminder for booking #{booking.reference_number}"
      rescue => e
        Rails.logger.error "Failed to send reminder for booking #{booking.reference_number}: #{e.message}"
      end
    end

    Rails.logger.info "SendBookingRemindersJob completed: #{sent_count} reminders sent"
    sent_count
  end
end
