class Api::V1::MaintenanceJobsController < ApplicationController
  before_action :set_maintenance_job, only: [:show, :update, :destroy, :complete, :attach_before_photos, :attach_after_photos]

  def index
    @maintenance_jobs = MaintenanceJob.active.includes(:product, :assigned_to)

    # Filters
    @maintenance_jobs = @maintenance_jobs.where(product_id: params[:product_id]) if params[:product_id].present?
    @maintenance_jobs = @maintenance_jobs.by_status(params[:status]) if params[:status].present?
    @maintenance_jobs = @maintenance_jobs.by_priority(params[:priority]) if params[:priority].present?
    @maintenance_jobs = @maintenance_jobs.where(assigned_to_id: params[:assigned_to_id]) if params[:assigned_to_id].present?
    @maintenance_jobs = @maintenance_jobs.overdue if params[:overdue] == 'true'

    render json: @maintenance_jobs.as_json(
      include: {
        product: { only: [:id, :name, :barcode] },
        assigned_to: { only: [:id, :name, :email] }
      },
      methods: [:overdue?, :cost]
    )
  end

  def show
    render json: @maintenance_job.as_json(
      include: {
        product: { only: [:id, :name, :barcode, :serial_numbers] },
        assigned_to: { only: [:id, :name, :email] }
      },
      methods: [:overdue?, :cost]
    )
  end

  def create
    @maintenance_job = MaintenanceJob.new(maintenance_job_params)

    if @maintenance_job.save
      render json: @maintenance_job.as_json(
        include: {
          product: { only: [:id, :name, :barcode] },
          assigned_to: { only: [:id, :name, :email] }
        },
        methods: [:overdue?, :cost]
      ), status: :created
    else
      render json: { errors: @maintenance_job.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @maintenance_job.update(maintenance_job_params)
      render json: @maintenance_job.as_json(
        include: {
          product: { only: [:id, :name, :barcode] },
          assigned_to: { only: [:id, :name, :email] }
        },
        methods: [:overdue?, :cost]
      )
    else
      render json: { errors: @maintenance_job.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @maintenance_job.update(deleted: true)
    render json: { message: 'Maintenance job deleted successfully' }
  end

  # POST /api/v1/maintenance_jobs/:id/complete
  # Mark job as completed with findings, parts used, and costs
  def complete
    unless params[:findings].present?
      return render json: {
        error: "Findings are required to complete a maintenance job"
      }, status: :unprocessable_entity
    end

    # Parse parts used if provided
    parts_used = params[:parts_used].present? ? JSON.parse(params[:parts_used]) : []

    # Parse cost breakdown if provided
    cost_breakdown = params[:cost_breakdown].present? ? JSON.parse(params[:cost_breakdown]) : {}

    completion_params = {
      status: :completed,
      completed_at: Time.current,
      performed_by: current_user,
      findings: params[:findings],
      parts_used: parts_used,
      cost_breakdown: cost_breakdown,
      actual_duration_hours: params[:actual_duration_hours]&.to_f
    }

    # Calculate total cost if not provided
    if params[:total_cost_cents].present?
      completion_params[:total_cost_cents] = params[:total_cost_cents].to_i
      completion_params[:total_cost_currency] = params[:total_cost_currency] || 'USD'
    elsif cost_breakdown.present?
      # Sum up parts and labor costs
      parts_total = cost_breakdown.dig('parts', 'total_cents') || 0
      labor_total = cost_breakdown.dig('labor', 'total_cents') || 0
      completion_params[:total_cost_cents] = parts_total + labor_total
      completion_params[:total_cost_currency] = cost_breakdown.dig('currency') || 'USD'
    end

    if @maintenance_job.update(completion_params)
      # If this was from a recurring schedule, update the schedule
      if @maintenance_job.maintenance_schedule_id.present?
        schedule = @maintenance_job.maintenance_schedule
        schedule.complete!(completed_by: current_user, notes: params[:findings])
      end

      # Update product maintenance status
      @maintenance_job.product.update_maintenance_status!

      render json: {
        message: "Maintenance job completed successfully",
        maintenance_job: detailed_job_json(@maintenance_job),
        next_scheduled_maintenance: @maintenance_job.maintenance_schedule&.next_due_date
      }
    else
      render json: {
        errors: @maintenance_job.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue JSON::ParserError => e
    render json: {
      error: "Invalid JSON format for parts_used or cost_breakdown: #{e.message}"
    }, status: :unprocessable_entity
  rescue ActiveRecord::RecordInvalid => e
    render json: {
      errors: e.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  # POST /api/v1/maintenance_jobs/:id/attach_before_photos
  # Attach before-maintenance photos
  def attach_before_photos
    unless params[:photos].present?
      return render json: {
        error: "No photos provided"
      }, status: :unprocessable_entity
    end

    @maintenance_job.before_photos.attach(params[:photos])

    render json: {
      message: "Before photos attached successfully",
      photos_count: @maintenance_job.before_photos.count,
      photos: @maintenance_job.before_photos.map do |photo|
        {
          id: photo.id,
          filename: photo.filename.to_s,
          content_type: photo.content_type,
          byte_size: photo.byte_size,
          url: rails_blob_url(photo)
        }
      end
    }
  rescue StandardError => e
    render json: {
      error: "Failed to attach photos: #{e.message}"
    }, status: :unprocessable_entity
  end

  # POST /api/v1/maintenance_jobs/:id/attach_after_photos
  # Attach after-maintenance photos
  def attach_after_photos
    unless params[:photos].present?
      return render json: {
        error: "No photos provided"
      }, status: :unprocessable_entity
    end

    unless @maintenance_job.completed?
      return render json: {
        error: "After photos can only be attached to completed maintenance jobs"
      }, status: :unprocessable_entity
    end

    @maintenance_job.after_photos.attach(params[:photos])

    render json: {
      message: "After photos attached successfully",
      photos_count: @maintenance_job.after_photos.count,
      photos: @maintenance_job.after_photos.map do |photo|
        {
          id: photo.id,
          filename: photo.filename.to_s,
          content_type: photo.content_type,
          byte_size: photo.byte_size,
          url: rails_blob_url(photo)
        }
      end
    }
  rescue StandardError => e
    render json: {
      error: "Failed to attach photos: #{e.message}"
    }, status: :unprocessable_entity
  end

  private

  def set_maintenance_job
    @maintenance_job = MaintenanceJob.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Maintenance job not found' }, status: :not_found
  end

  def maintenance_job_params
    params.require(:maintenance_job).permit(
      :product_id, :title, :description, :status, :priority,
      :scheduled_date, :completed_date, :assigned_to_id,
      :cost_cents, :cost_currency, :notes
    )
  end

  def detailed_job_json(job)
    {
      id: job.id,
      title: job.title,
      description: job.description,
      maintenance_type: job.maintenance_type,
      status: job.status,
      priority: job.priority,
      scheduled_for: job.scheduled_for,
      started_at: job.started_at,
      completed_at: job.completed_at,
      product: {
        id: job.product.id,
        name: job.product.name,
        barcode: job.product.barcode
      },
      assigned_to: job.assigned_to ? {
        id: job.assigned_to.id,
        name: job.assigned_to.name,
        email: job.assigned_to.email
      } : nil,
      performed_by: job.performed_by ? {
        id: job.performed_by.id,
        name: job.performed_by.name,
        email: job.performed_by.email
      } : nil,
      recurring: job.recurring,
      maintenance_schedule_id: job.maintenance_schedule_id,
      estimated_duration_hours: job.estimated_duration_hours,
      actual_duration_hours: job.actual_duration_hours,
      findings: job.findings,
      parts_used: job.parts_used,
      required_parts: job.required_parts,
      cost_breakdown: job.cost_breakdown,
      total_cost: job.total_cost_cents ? {
        amount: job.total_cost_cents,
        currency: job.total_cost_currency,
        formatted: Money.new(job.total_cost_cents, job.total_cost_currency || 'USD').format
      } : nil,
      before_photos: job.before_photos.attached? ? job.before_photos.map { |photo|
        {
          id: photo.id,
          filename: photo.filename.to_s,
          url: rails_blob_url(photo)
        }
      } : [],
      after_photos: job.after_photos.attached? ? job.after_photos.map { |photo|
        {
          id: photo.id,
          filename: photo.filename.to_s,
          url: rails_blob_url(photo)
        }
      } : [],
      overdue: job.overdue?,
      created_at: job.created_at,
      updated_at: job.updated_at
    }
  end
end
