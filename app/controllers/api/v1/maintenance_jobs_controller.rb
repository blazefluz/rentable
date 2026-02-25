class Api::V1::MaintenanceJobsController < ApplicationController
  before_action :set_maintenance_job, only: [:show, :update, :destroy]

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
end
