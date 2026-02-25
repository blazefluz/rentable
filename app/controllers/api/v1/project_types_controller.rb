class Api::V1::ProjectTypesController < ApplicationController
  before_action :set_project_type, only: [:show, :update, :destroy]

  def index
    @project_types = ProjectType.active
    @project_types = ProjectType.all if params[:include_deleted] == 'true'

    render json: @project_types.as_json(include: { bookings: { only: [:id, :reference_number] } })
  end

  def show
    render json: @project_type.as_json(include: { bookings: { only: [:id, :reference_number, :status] } })
  end

  def create
    @project_type = ProjectType.new(project_type_params)

    if @project_type.save
      render json: @project_type, status: :created
    else
      render json: { errors: @project_type.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @project_type.update(project_type_params)
      render json: @project_type
    else
      render json: { errors: @project_type.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @project_type.update(deleted: true)
    render json: { message: 'Project type deleted successfully' }
  end

  private

  def set_project_type
    @project_type = ProjectType.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Project type not found' }, status: :not_found
  end

  def project_type_params
    params.require(:project_type).permit(
      :name, :description, :active, :default_duration_days,
      :requires_approval, :auto_confirm,
      feature_flags: {}, settings: {}
    )
  end
end
