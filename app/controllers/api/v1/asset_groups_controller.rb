class Api::V1::AssetGroupsController < ApplicationController
  before_action :set_asset_group, only: [:show, :update, :destroy, :add_product, :remove_product]

  def index
    @groups = AssetGroup.active.includes(:products)
    render json: @groups.as_json(include: { products: { only: [:id, :name] } })
  end

  def show
    render json: @group.as_json(include: { products: { only: [:id, :name, :barcode] } })
  end

  def create
    @group = AssetGroup.new(asset_group_params)

    if @group.save
      render json: @group, status: :created
    else
      render json: { errors: @group.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @group.update(asset_group_params)
      render json: @group
    else
      render json: { errors: @group.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def add_product
    product = Product.find(params[:product_id])
    @group.products << product unless @group.products.include?(product)
    render json: @group.as_json(include: { products: { only: [:id, :name, :barcode] } })
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Product not found' }, status: :not_found
  end

  def remove_product
    product = Product.find(params[:product_id])
    @group.products.delete(product)
    render json: @group.as_json(include: { products: { only: [:id, :name, :barcode] } })
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Product not found' }, status: :not_found
  end

  def destroy
    @group.update(deleted: true)
    render json: { message: 'Asset group deleted successfully' }
  end

  private

  def set_asset_group
    @group = AssetGroup.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Asset group not found' }, status: :not_found
  end

  def asset_group_params
    params.require(:asset_group).permit(:name, :description)
  end
end
