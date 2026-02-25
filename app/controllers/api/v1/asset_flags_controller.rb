class Api::V1::AssetFlagsController < ApplicationController
  before_action :set_asset_flag, only: [:show, :update, :destroy]

  def index
    @flags = AssetFlag.active.includes(:products)
    render json: @flags.as_json(include: { products: { only: [:id, :name] } })
  end

  def show
    render json: @flag.as_json(include: { products: { only: [:id, :name, :barcode] } })
  end

  def create
    @flag = AssetFlag.new(asset_flag_params)

    if @flag.save
      render json: @flag, status: :created
    else
      render json: { errors: @flag.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @flag.update(asset_flag_params)
      render json: @flag
    else
      render json: { errors: @flag.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @flag.update(deleted: true)
    render json: { message: 'Asset flag deleted successfully' }
  end

  private

  def set_asset_flag
    @flag = AssetFlag.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Asset flag not found' }, status: :not_found
  end

  def asset_flag_params
    params.require(:asset_flag).permit(:name, :color, :icon, :description)
  end
end
