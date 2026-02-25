class Api::V1::ProductInstancesController < ApplicationController
  before_action :set_product, only: [:index, :create]
  before_action :set_product_instance, only: [:show, :update, :destroy]

  def index
    if params[:product_id]
      @instances = @product.product_instances.active.includes(:current_location)
    else
      @instances = ProductInstance.active.includes(:product, :current_location)
    end

    render json: @instances.as_json(
      include: {
        product: { only: [:id, :name] },
        current_location: { only: [:id, :name] }
      }
    )
  end

  def show
    render json: @instance.as_json(
      include: {
        product: { only: [:id, :name, :barcode] },
        current_location: { only: [:id, :name, :barcode] }
      }
    )
  end

  def create
    @instance = @product.product_instances.new(product_instance_params)

    if @instance.save
      render json: @instance, status: :created
    else
      render json: { errors: @instance.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @instance.update(product_instance_params)
      render json: @instance
    else
      render json: { errors: @instance.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @instance.update(deleted: true)
    render json: { message: 'Product instance deleted successfully' }
  end

  private

  def set_product
    @product = Product.find(params[:product_id]) if params[:product_id]
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Product not found' }, status: :not_found
  end

  def set_product_instance
    @instance = ProductInstance.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Product instance not found' }, status: :not_found
  end

  def product_instance_params
    params.require(:product_instance).permit(
      :serial_number,
      :asset_tag,
      :condition,
      :status,
      :purchase_date,
      :purchase_price_cents,
      :purchase_price_currency,
      :current_location_id,
      :notes
    )
  end
end
