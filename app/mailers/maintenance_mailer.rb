class MaintenanceMailer < ApplicationMailer
  default from: 'maintenance@rentable.com'

  # Send notification when maintenance is due soon (within 7 days)
  # @param schedule [MaintenanceSchedule] The maintenance schedule that is due
  # @param recipient [User] The user to notify (assigned technician or manager)
  def maintenance_due(schedule, recipient)
    @schedule = schedule
    @product = schedule.product
    @recipient = recipient
    @days_until_due = ((schedule.next_due_date - Time.current) / 1.day).ceil

    mail(
      to: recipient.email,
      subject: "Maintenance Due Soon: #{@product.name} - #{@schedule.name}"
    )
  end

  # Send notification when maintenance is overdue
  # @param schedule [MaintenanceSchedule] The overdue maintenance schedule
  # @param recipient [User] The user to notify
  def maintenance_overdue(schedule, recipient)
    @schedule = schedule
    @product = schedule.product
    @recipient = recipient
    @days_overdue = ((Time.current - schedule.next_due_date) / 1.day).ceil

    mail(
      to: recipient.email,
      subject: "OVERDUE MAINTENANCE: #{@product.name} - #{@schedule.name}",
      priority: :high
    )
  end

  # Send notification when maintenance job is completed
  # @param job [MaintenanceJob] The completed maintenance job
  # @param recipients [Array<User>] Users to notify (manager, assigned technician)
  def maintenance_completed(job, recipients)
    @job = job
    @product = job.product
    @performed_by = job.performed_by
    @findings = job.findings
    @parts_used = job.parts_used
    @total_cost = job.total_cost_cents ? Money.new(job.total_cost_cents, job.total_cost_currency || 'USD') : nil

    recipient_emails = recipients.map(&:email)

    mail(
      to: recipient_emails,
      subject: "Maintenance Completed: #{@product.name} - #{@job.title}"
    )
  end

  # Send notification when a maintenance job is assigned to a technician
  # @param job [MaintenanceJob] The assigned maintenance job
  # @param technician [User] The technician assigned to the job
  def job_assigned(job, technician)
    @job = job
    @product = job.product
    @technician = technician
    @scheduled_for = job.scheduled_for
    @priority = job.priority
    @estimated_duration = job.estimated_duration_hours

    mail(
      to: technician.email,
      subject: "New Maintenance Job Assigned: #{@product.name}",
      priority: job.priority == 'critical' ? :high : :normal
    )
  end
end
