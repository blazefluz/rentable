class SendOverdueNotificationsJob < ApplicationJob
  queue_as :default

  def perform
    # Find all overdue line items that haven't been notified yet
    overdue_items = BookingLineItem.overdue.where(overdue_notified_at: nil)

    overdue_items.find_each do |item|
      # Send notification email
      begin
        BookingMailer.overdue_notification(item).deliver_later
        item.mark_overdue_notification_sent!
        Rails.logger.info "Sent overdue notification for BookingLineItem ##{item.id}"
      rescue => e
        Rails.logger.error "Failed to send overdue notification for BookingLineItem ##{item.id}: #{e.message}"
      end
    end

    # Find items that are still overdue and were notified more than 3 days ago (send reminder)
    overdue_reminded_items = BookingLineItem.overdue
      .where('overdue_notified_at < ?', 3.days.ago)
      .where('last_overdue_reminder_sent_at IS NULL OR last_overdue_reminder_sent_at < ?', 1.day.ago)

    overdue_reminded_items.find_each do |item|
      begin
        BookingMailer.overdue_reminder(item).deliver_later
        item.update(last_overdue_reminder_sent_at: Time.current)
        Rails.logger.info "Sent overdue reminder for BookingLineItem ##{item.id}"
      rescue => e
        Rails.logger.error "Failed to send overdue reminder for BookingLineItem ##{item.id}: #{e.message}"
      end
    end

    # Find late deliveries that need notification
    late_deliveries = BookingLineItem.late_for_delivery
      .where(delivery_late_notified_at: nil)

    late_deliveries.find_each do |item|
      begin
        BookingMailer.late_delivery_notification(item).deliver_later
        item.update(delivery_late_notified_at: Time.current)
        Rails.logger.info "Sent late delivery notification for BookingLineItem ##{item.id}"
      rescue => e
        Rails.logger.error "Failed to send late delivery notification for BookingLineItem ##{item.id}: #{e.message}"
      end
    end

    Rails.logger.info "SendOverdueNotificationsJob completed: #{overdue_items.count} overdue notifications, #{overdue_reminded_items.count} reminders, #{late_deliveries.count} late delivery notifications"
  end
end
