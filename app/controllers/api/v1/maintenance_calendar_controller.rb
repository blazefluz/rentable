class Api::V1::MaintenanceCalendarController < ApplicationController
  before_action :authenticate_user!
  before_action :set_date_range

  def index
    # Get all maintenance jobs and schedules within the date range
    jobs = current_company.maintenance_jobs
      .active
      .where('scheduled_date >= ? AND scheduled_date <= ?', @start_date, @end_date)
      .includes(:product, :assigned_to)

    schedules = current_company.maintenance_schedules
      .enabled
      .where('next_due_date >= ? AND next_due_date <= ?', @start_date, @end_date)
      .includes(:product, :assigned_to)

    # Group by week or month based on view parameter
    calendar_events = build_calendar_events(jobs, schedules)

    # Detect conflicts (double-booked technicians)
    conflicts = detect_conflicts(jobs)

    render json: {
      calendar_events: calendar_events,
      conflicts: conflicts,
      date_range: {
        start_date: @start_date,
        end_date: @end_date
      },
      summary: {
        total_jobs: jobs.count,
        total_schedules: schedules.count,
        pending_jobs: jobs.where(status: :pending).count,
        in_progress_jobs: jobs.where(status: :in_progress).count,
        overdue_jobs: jobs.overdue.count,
        conflicts_count: conflicts.count
      }
    }, status: :ok
  end

  private

  def set_date_range
    # Default to current month if no dates provided
    @start_date = params[:start_date]&.to_date || Date.today.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.today.end_of_month
  end

  def build_calendar_events(jobs, schedules)
    events = []

    # Add maintenance jobs
    jobs.each do |job|
      events << {
        id: job.id,
        type: 'maintenance_job',
        title: job.title,
        product_id: job.product_id,
        product_name: job.product.name,
        scheduled_date: job.scheduled_date,
        status: job.status,
        priority: job.priority,
        maintenance_type: job.maintenance_type,
        assigned_to: job.assigned_to ? {
          id: job.assigned_to.id,
          name: job.assigned_to.name || job.assigned_to.email
        } : nil,
        estimated_duration: job.estimated_duration_hours,
        overdue: job.overdue?,
        color: status_color(job.status),
        icon: maintenance_type_icon(job.maintenance_type)
      }
    end

    # Add maintenance schedules
    schedules.each do |schedule|
      events << {
        id: schedule.id,
        type: 'maintenance_schedule',
        title: schedule.name,
        product_id: schedule.product_id,
        product_name: schedule.product.name,
        scheduled_date: schedule.next_due_date,
        status: schedule.status,
        frequency: schedule.schedule_description,
        assigned_to: schedule.assigned_to ? {
          id: schedule.assigned_to.id,
          name: schedule.assigned_to.name || schedule.assigned_to.email
        } : nil,
        due_soon: schedule.due_soon?,
        overdue: schedule.overdue?,
        color: schedule_status_color(schedule),
        icon: 'calendar'
      }
    end

    # Group by week/month if requested
    case params[:group_by]
    when 'week'
      group_events_by_week(events)
    when 'month'
      group_events_by_month(events)
    else
      # Return events sorted by date
      events.sort_by { |e| e[:scheduled_date] }
    end
  end

  def group_events_by_week(events)
    events.group_by do |event|
      event[:scheduled_date].beginning_of_week
    end.map do |week_start, week_events|
      {
        week_starting: week_start,
        week_ending: week_start + 6.days,
        events: week_events.sort_by { |e| e[:scheduled_date] },
        count: week_events.count
      }
    end
  end

  def group_events_by_month(events)
    events.group_by do |event|
      event[:scheduled_date].beginning_of_month
    end.map do |month_start, month_events|
      {
        month: month_start.strftime('%B %Y'),
        month_start: month_start,
        month_end: month_start.end_of_month,
        events: month_events.sort_by { |e| e[:scheduled_date] },
        count: month_events.count
      }
    end
  end

  def detect_conflicts(jobs)
    conflicts = []

    # Group jobs by assigned technician and date
    jobs_by_tech = jobs.where.not(assigned_to_id: nil)
      .group_by { |job| [job.assigned_to_id, job.scheduled_date.to_date] }

    jobs_by_tech.each do |(tech_id, date), tech_jobs|
      next if tech_jobs.count < 2

      # Check for overlapping time slots
      tech_jobs.combination(2).each do |job1, job2|
        # Simplified conflict detection - if same day and both have estimated durations
        if job1.estimated_duration_hours && job2.estimated_duration_hours
          conflicts << {
            technician_id: tech_id,
            technician_name: job1.assigned_to.name || job1.assigned_to.email,
            date: date,
            job1: { id: job1.id, title: job1.title, time: job1.scheduled_date },
            job2: { id: job2.id, title: job2.title, time: job2.scheduled_date }
          }
        end
      end
    end

    conflicts
  end

  def status_color(status)
    case status.to_sym
    when :pending then 'blue'
    when :in_progress then 'yellow'
    when :completed then 'green'
    when :cancelled then 'gray'
    when :on_hold then 'orange'
    else 'gray'
    end
  end

  def schedule_status_color(schedule)
    return 'red' if schedule.overdue?
    return 'orange' if schedule.due_soon?
    return 'green' if schedule.status_completed?
    'blue'
  end

  def maintenance_type_icon(type)
    case type.to_s
    when 'routine' then 'wrench'
    when 'inspection' then 'search'
    when 'calibration' then 'sliders'
    when 'cleaning' then 'droplet'
    when 'lubrication' then 'oil'
    else 'tool'
    end
  end
end
