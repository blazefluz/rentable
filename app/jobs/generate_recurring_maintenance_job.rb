class GenerateRecurringMaintenanceJob < ApplicationJob
  queue_as :default

  def perform
    # Find all maintenance schedules that are due and enabled
    due_schedules = MaintenanceSchedule.enabled.due_soon(0) # Due today or earlier

    due_schedules.each do |schedule|
      # Create a maintenance job from the schedule
      create_maintenance_job_from_schedule(schedule)
    end

    # Also find recurring maintenance jobs that need to generate their next occurrence
    recurring_jobs = MaintenanceJob.due_for_generation

    recurring_jobs.each do |job|
      job.generate_next_occurrence
    end

    Rails.logger.info "[GenerateRecurringMaintenanceJob] Generated jobs for #{due_schedules.count} schedules and #{recurring_jobs.count} recurring jobs"
  end

  private

  def create_maintenance_job_from_schedule(schedule)
    # Check if a job already exists for this schedule's current due date
    existing_job = MaintenanceJob.find_by(
      product: schedule.product,
      scheduled_date: schedule.next_due_date.to_date,
      title: schedule.name
    )

    return if existing_job # Don't create duplicate jobs

    # Create the maintenance job
    MaintenanceJob.create!(
      product: schedule.product,
      assigned_to: schedule.assigned_to,
      title: schedule.name,
      description: "Scheduled maintenance: #{schedule.schedule_description}",
      scheduled_date: schedule.next_due_date,
      status: :pending,
      priority: determine_priority(schedule),
      maintenance_type: :routine,
      is_recurring: false,
      auto_generate: false
    )

    # Update schedule status
    schedule.update(status: :in_progress)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "[GenerateRecurringMaintenanceJob] Failed to create job for schedule #{schedule.id}: #{e.message}"
  end

  def determine_priority(schedule)
    if schedule.overdue?
      :urgent
    elsif schedule.due_soon?(3) # Due within 3 days
      :high
    elsif schedule.due_soon?(7) # Due within 7 days
      :medium
    else
      :low
    end
  end
end
