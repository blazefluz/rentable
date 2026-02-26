class SendPaymentRemindersJob < ApplicationJob
  queue_as :default

  # Run daily to send payment reminders and escalate collection status
  def perform
    Rails.logger.info "=== Starting Payment Reminders Job ==="

    # Update AR metrics for all bookings with balance
    update_ar_metrics

    # Send reminders for overdue bookings
    send_friendly_reminders
    send_first_notices
    send_second_notices
    send_final_notices
    escalate_to_collections

    Rails.logger.info "=== Payment Reminders Job Complete ==="
  end

  private

  def update_ar_metrics
    Rails.logger.info "Updating AR metrics..."

    Booking.with_balance_due.find_each do |booking|
      booking.update_ar_metrics!
    rescue => e
      Rails.logger.error "Error updating AR metrics for booking #{booking.id}: #{e.message}"
    end
  end

  def send_friendly_reminders
    # 7 days past due - friendly reminder
    bookings = Booking.where(days_past_due: 7..13)
                      .where(collection_status: :current_status)
                      .needs_reminder

    Rails.logger.info "Sending #{bookings.count} friendly reminders..."

    bookings.find_each do |booking|
      booking.send_payment_reminder!(reminder_type: :friendly)
      # BookingMailer.payment_reminder(booking, :friendly).deliver_later
      Rails.logger.info "  Sent friendly reminder for booking #{booking.reference_number}"
    rescue => e
      Rails.logger.error "Error sending reminder for booking #{booking.id}: #{e.message}"
    end
  end

  def send_first_notices
    # 14-29 days past due - first notice
    bookings = Booking.where(days_past_due: 14..29)
                      .where(collection_status: [:current_status, :reminder_sent])
                      .needs_reminder

    Rails.logger.info "Sending #{bookings.count} first notices..."

    bookings.find_each do |booking|
      booking.send_payment_reminder!(reminder_type: :first_notice)
      booking.update!(collection_status: :first_notice)
      # BookingMailer.payment_reminder(booking, :first_notice).deliver_later
      Rails.logger.info "  Sent first notice for booking #{booking.reference_number}"
    rescue => e
      Rails.logger.error "Error sending first notice for booking #{booking.id}: #{e.message}"
    end
  end

  def send_second_notices
    # 30-59 days past due - second notice
    bookings = Booking.where(days_past_due: 30..59)
                      .where(collection_status: [:reminder_sent, :first_notice])
                      .needs_reminder

    Rails.logger.info "Sending #{bookings.count} second notices..."

    bookings.find_each do |booking|
      booking.send_payment_reminder!(reminder_type: :second_notice)
      booking.update!(collection_status: :second_notice)
      # BookingMailer.payment_reminder(booking, :second_notice).deliver_later
      Rails.logger.info "  Sent second notice for booking #{booking.reference_number}"
    rescue => e
      Rails.logger.error "Error sending second notice for booking #{booking.id}: #{e.message}"
    end
  end

  def send_final_notices
    # 60-89 days past due - final notice
    bookings = Booking.where(days_past_due: 60..89)
                      .where(collection_status: [:first_notice, :second_notice])
                      .needs_reminder

    Rails.logger.info "Sending #{bookings.count} final notices..."

    bookings.find_each do |booking|
      booking.send_payment_reminder!(reminder_type: :final_notice)
      booking.update!(collection_status: :final_notice)
      # BookingMailer.payment_reminder(booking, :final_notice).deliver_later
      Rails.logger.info "  Sent final notice for booking #{booking.reference_number}"
    rescue => e
      Rails.logger.error "Error sending final notice for booking #{booking.id}: #{e.message}"
    end
  end

  def escalate_to_collections
    # 90+ days past due - escalate to collections
    bookings = Booking.where(days_past_due: 90..)
                      .where(collection_status: [:second_notice, :final_notice])

    Rails.logger.info "Escalating #{bookings.count} bookings to collections..."

    bookings.find_each do |booking|
      booking.update!(
        collection_status: :in_collections,
        collection_notes: "[#{Time.current}] Auto-escalated to collections - 90+ days overdue. Balance: #{Money.new(booking.balance_due, booking.total_price_currency).format}"
      )
      # Notify collections team
      # CollectionsMailer.new_collection(booking).deliver_later
      Rails.logger.info "  Escalated booking #{booking.reference_number} to collections"
    rescue => e
      Rails.logger.error "Error escalating booking #{booking.id}: #{e.message}"
    end
  end
end
