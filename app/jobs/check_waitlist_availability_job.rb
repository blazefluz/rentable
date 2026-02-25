# app/jobs/check_waitlist_availability_job.rb
class CheckWaitlistAvailabilityJob < ApplicationJob
  queue_as :default

  # Run this job hourly to check if waitlisted items are now available
  def perform
    # Find pending waitlist entries
    pending_entries = WaitlistEntry.status_waiting.where(notified_at: nil)

    notified_count = 0

    pending_entries.find_each do |entry|
      begin
        # Check if the item is now available
        if entry.bookable.available?(entry.start_date, entry.end_date, entry.quantity)
          # Notify the customer
          entry.notify!
          WaitlistMailer.availability_notification(entry).deliver_now
          notified_count += 1
          Rails.logger.info "Notified waitlist entry #{entry.id} - #{entry.bookable.name} is available"
        end
      rescue => e
        Rails.logger.error "Failed to check waitlist entry #{entry.id}: #{e.message}"
      end
    end

    Rails.logger.info "CheckWaitlistAvailabilityJob completed: #{notified_count} notifications sent"
    notified_count
  end
end
