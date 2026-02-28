# app/services/maintenance_schedule_service.rb
class MaintenanceScheduleService
  class << self
    # Create a new maintenance schedule
    def create_schedule(product:, params:, company:)
      schedule = product.maintenance_schedules.build(params)
      schedule.company = company
      schedule.next_due_date = calculate_initial_due_date(schedule) if schedule.next_due_date.blank?

      if schedule.save
        { success: true, schedule: schedule }
      else
        { success: false, errors: schedule.errors }
      end
    end

    # Update an existing maintenance schedule
    def update_schedule(schedule:, params:)
      # If frequency or interval changes, recalculate next due date
      recalculate = params[:frequency].present? || params[:interval_value].present? || params[:interval_unit].present?

      if schedule.update(params)
        schedule.update(next_due_date: schedule.calculate_next_due_date) if recalculate
        { success: true, schedule: schedule }
      else
        { success: false, errors: schedule.errors }
      end
    end

    # Complete a maintenance task
    def complete_maintenance(schedule:, completed_by:, notes: nil)
      ActiveRecord::Base.transaction do
        # Create maintenance log
        log = schedule.maintenance_logs.create!(
          performed_by: completed_by,
          completed_at: Time.current,
          notes: notes
        )

        # Update schedule
        schedule.update!(
          last_completed_at: Time.current,
          next_due_date: schedule.calculate_next_due_date,
          status: :scheduled
        )

        # Remove any availability blocks if product was blocked for maintenance
        remove_availability_block(schedule)

        { success: true, schedule: schedule, log: log }
      end
    rescue ActiveRecord::RecordInvalid => e
      { success: false, errors: e.record.errors }
    end

    # Get upcoming maintenance for a company
    def upcoming_maintenance(company:, days: 7)
      MaintenanceSchedule
        .where(company: company)
        .due_soon(days)
        .includes(:product, :assigned_to)
        .order(:next_due_date)
    end

    # Get overdue maintenance for a company
    def overdue_maintenance(company:)
      MaintenanceSchedule
        .where(company: company)
        .overdue
        .includes(:product, :assigned_to)
        .order(:next_due_date)
    end

    # Get maintenance schedules for a specific product
    def product_schedules(product:)
      product.maintenance_schedules
        .enabled
        .includes(:assigned_to, :maintenance_logs)
        .order(:next_due_date)
    end

    # Mark overdue schedules (typically run by a background job)
    def mark_overdue_schedules(company: nil)
      scope = MaintenanceSchedule.enabled
      scope = scope.where(company: company) if company.present?

      overdue_schedules = scope.where('next_due_date < ?', Time.current).where.not(status: 'completed')

      count = 0
      overdue_schedules.find_each do |schedule|
        schedule.mark_overdue!
        count += 1
      end

      { success: true, count: count }
    end

    # Disable a maintenance schedule
    def disable_schedule(schedule:)
      if schedule.update(enabled: false)
        { success: true, schedule: schedule }
      else
        { success: false, errors: schedule.errors }
      end
    end

    # Enable a maintenance schedule
    def enable_schedule(schedule:)
      if schedule.update(enabled: true)
        # Recalculate next due date if needed
        schedule.update(next_due_date: schedule.calculate_next_due_date) if schedule.next_due_date.blank?
        { success: true, schedule: schedule }
      else
        { success: false, errors: schedule.errors }
      end
    end

    private

    def calculate_initial_due_date(schedule)
      case schedule.frequency
      when 'hours_based'
        schedule.interval_value.hours.from_now
      when 'days_based'
        schedule.interval_value.days.from_now
      when 'usage_based'
        # For usage-based, estimate 30 days initially (will be recalculated after first completion)
        30.days.from_now
      else
        30.days.from_now
      end
    end

    def remove_availability_block(schedule)
      # If there's an AvailabilityBlock system, remove blocks associated with this maintenance
      # This is for future integration with availability blocking system
      # For now, this is a placeholder
      nil
    end
  end
end
