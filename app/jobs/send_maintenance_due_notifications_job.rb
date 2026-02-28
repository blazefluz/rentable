class SendMaintenanceDueNotificationsJob < ApplicationJob
  queue_as :default

  def perform
    # Send notifications for schedules due soon (within 7 days)
    send_due_soon_notifications

    # Send notifications for overdue schedules
    send_overdue_notifications

    # Send notifications for upcoming maintenance jobs
    send_job_notifications
  end

  private

  def send_due_soon_notifications
    due_soon_schedules = MaintenanceSchedule.enabled.due_soon(7)

    due_soon_schedules.each do |schedule|
      days_until_due = schedule.days_until_due

      # Send notification if due within 7, 3, or 1 days
      if [7, 3, 1].include?(days_until_due)
        NotificationService.send_maintenance_due_notification(schedule, days_until_due)
      end
    end

    Rails.logger.info "[SendMaintenanceDueNotificationsJob] Sent due soon notifications for #{due_soon_schedules.count} schedules"
  end

  def send_overdue_notifications
    overdue_schedules = MaintenanceSchedule.enabled.overdue

    overdue_schedules.each do |schedule|
      NotificationService.send_overdue_notification(schedule)

      # Mark schedule as overdue if not already
      schedule.mark_overdue! unless schedule.status_overdue?
    end

    Rails.logger.info "[SendMaintenanceDueNotificationsJob] Sent overdue notifications for #{overdue_schedules.count} schedules"
  end

  def send_job_notifications
    # Find jobs that are due within the next 3 days and haven't been notified
    upcoming_jobs = MaintenanceJob.active
      .where(status: [:pending, :in_progress])
      .where('scheduled_date >= ? AND scheduled_date <= ?', Date.today, 3.days.from_now)
      .where('notified_at IS NULL OR notified_at < ?', 24.hours.ago)

    upcoming_jobs.each do |job|
      next unless job.assigned_to.present?

      NotificationService.send_maintenance_assigned_notification(job)

      # Update notified timestamp
      job.update_column(:notified_at, Time.current)
    end

    Rails.logger.info "[SendMaintenanceDueNotificationsJob] Sent job notifications for #{upcoming_jobs.count} jobs"
  end
end
