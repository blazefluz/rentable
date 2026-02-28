# app/services/notification_service.rb
class NotificationService
  class << self
    # Send maintenance due notification
    def send_maintenance_due_notification(schedule)
      return if recently_notified?(schedule, :due_notification)

      # Send email notification to assigned user or find manager
      recipient = schedule.assigned_to || find_recipient_for_schedule(schedule)
      return unless recipient&.email.present?

      MaintenanceMailer.maintenance_due(schedule, recipient).deliver_later

      # Track notification
      track_notification(schedule, :due_notification)
    end

    # Send overdue notification
    def send_overdue_notification(schedule)
      return if recently_notified?(schedule, :overdue_notification)

      # Send email notification to assigned user or find manager
      recipient = schedule.assigned_to || find_recipient_for_schedule(schedule)
      return unless recipient&.email.present?

      MaintenanceMailer.maintenance_overdue(schedule, recipient).deliver_later

      # Track notification
      track_notification(schedule, :overdue_notification)
    end

    # Send notification for completed maintenance job
    def send_maintenance_completed_notification(job)
      # Notify manager and assigned technician
      recipients = find_recipients_for_completed_job(job)
      return if recipients.empty?

      MaintenanceMailer.maintenance_completed(job, recipients).deliver_later
    end

    # Send notification when maintenance job is assigned
    def send_job_assigned_notification(job)
      return unless job.assigned_to&.email.present?

      MaintenanceMailer.job_assigned(job, job.assigned_to).deliver_later
    end

    private

    # Check if notification was sent recently (within 24 hours)
    def recently_notified?(schedule, notification_type)
      cache_key = notification_cache_key(schedule, notification_type)
      Rails.cache.read(cache_key).present?
    end

    # Track that a notification was sent
    def track_notification(schedule, notification_type)
      cache_key = notification_cache_key(schedule, notification_type)
      # Cache for 24 hours to prevent duplicate notifications
      Rails.cache.write(cache_key, Time.current, expires_in: 24.hours)

      # Update schedule's notified_at timestamp if it has one
      schedule.update_column(:notified_at, Time.current) if schedule.respond_to?(:notified_at)
    end

    # Generate cache key for notification tracking
    def notification_cache_key(schedule, notification_type)
      "maintenance_notification:#{schedule.class.name}:#{schedule.id}:#{notification_type}"
    end

    # Find appropriate recipient for maintenance schedule notifications
    def find_recipient_for_schedule(schedule)
      # Try to find manager or admin in the company
      company = schedule.company
      company.users.where(role: [:admin, :manager]).first || company.users.first
    end

    # Find recipients for completed job notification
    def find_recipients_for_completed_job(job)
      recipients = []

      # Add managers and admins
      job.product.company.users.where(role: [:admin, :manager]).each do |user|
        recipients << user if user.email.present?
      end

      # Add the technician who performed the work if different
      if job.performed_by && job.performed_by.email.present?
        recipients << job.performed_by unless recipients.include?(job.performed_by)
      end

      recipients.uniq
    end
  end
end
