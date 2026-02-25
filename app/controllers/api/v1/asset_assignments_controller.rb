class Api::V1::AssetAssignmentsController < ApplicationController
  before_action :set_asset_assignment, only: [:show, :update, :destroy, :return_asset]

  def index
    @assignments = AssetAssignment.active.includes(:product, :assigned_to)

    # Filters
    @assignments = @assignments.where(product_id: params[:product_id]) if params[:product_id].present?
    @assignments = @assignments.where(assigned_to_id: params[:assigned_to_id], assigned_to_type: params[:assigned_to_type]) if params[:assigned_to_id].present?
    @assignments = @assignments.where(status: params[:status]) if params[:status].present?
    @assignments = @assignments.current if params[:current] == 'true'
    @assignments = @assignments.overdue_assignments if params[:overdue] == 'true'

    render json: @assignments.as_json(
      include: {
        product: { only: [:id, :name, :barcode, :serial_numbers] },
        assigned_to: { only: [:id, :name, :email] }
      },
      methods: [:overdue?, :duration_days, :actual_duration_days]
    )
  end

  def show
    render json: @assignment.as_json(
      include: {
        product: { only: [:id, :name, :barcode, :serial_numbers] },
        assigned_to: { only: [:id, :name, :email] }
      },
      methods: [:overdue?, :duration_days, :actual_duration_days]
    )
  end

  def create
    @assignment = AssetAssignment.new(asset_assignment_params)

    if @assignment.save
      render json: @assignment.as_json(
        include: {
          product: { only: [:id, :name, :barcode] },
          assigned_to: { only: [:id, :name, :email] }
        },
        methods: [:overdue?, :duration_days]
      ), status: :created
    else
      render json: { errors: @assignment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @assignment.update(asset_assignment_params)
      render json: @assignment.as_json(
        include: {
          product: { only: [:id, :name, :barcode] },
          assigned_to: { only: [:id, :name, :email] }
        },
        methods: [:overdue?, :duration_days, :actual_duration_days]
      )
    else
      render json: { errors: @assignment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def return_asset
    if @assignment.update(status: :returned, returned_date: Time.current)
      render json: @assignment.as_json(
        include: {
          product: { only: [:id, :name, :barcode] },
          assigned_to: { only: [:id, :name, :email] }
        },
        methods: [:actual_duration_days]
      )
    else
      render json: { errors: @assignment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @assignment.update(deleted: true)
    render json: { message: 'Asset assignment deleted successfully' }
  end

  private

  def set_asset_assignment
    @assignment = AssetAssignment.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Asset assignment not found' }, status: :not_found
  end

  def asset_assignment_params
    params.require(:asset_assignment).permit(
      :product_id, :assigned_to_id, :assigned_to_type,
      :start_date, :end_date, :purpose, :notes, :status, :returned_date
    )
  end
end
