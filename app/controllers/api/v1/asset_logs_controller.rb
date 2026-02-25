class Api::V1::AssetLogsController < ApplicationController
  before_action :set_asset_log, only: [:show]

  def index
    @logs = AssetLog.includes(:product, :user).recent

    # Filters
    @logs = @logs.by_product(params[:product_id]) if params[:product_id].present?
    @logs = @logs.by_type(params[:log_type]) if params[:log_type].present?
    @logs = @logs.by_user(params[:user_id]) if params[:user_id].present?
    @logs = @logs.where('logged_at >= ?', params[:from_date]) if params[:from_date].present?
    @logs = @logs.where('logged_at <= ?', params[:to_date]) if params[:to_date].present?

    # Pagination
    page = params[:page] || 1
    per_page = params[:per_page] || 50
    @logs = @logs.page(page).per(per_page)

    render json: @logs.as_json(
      include: {
        product: { only: [:id, :name, :barcode] },
        user: { only: [:id, :name, :email] }
      }
    )
  end

  def show
    render json: @log.as_json(
      include: {
        product: { only: [:id, :name, :barcode, :serial_numbers] },
        user: { only: [:id, :name, :email] }
      }
    )
  end

  def create
    @log = AssetLog.new(asset_log_params)

    if @log.save
      render json: @log.as_json(
        include: {
          product: { only: [:id, :name, :barcode] },
          user: { only: [:id, :name, :email] }
        }
      ), status: :created
    else
      render json: { errors: @log.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_asset_log
    @log = AssetLog.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Asset log entry not found' }, status: :not_found
  end

  def asset_log_params
    params.require(:asset_log).permit(:product_id, :user_id, :log_type, :description, :metadata, :logged_at)
  end
end
