class Api::V1::ProductBundlesController < ApplicationController
  before_action :set_product_bundle, only: [:show, :update, :destroy]

  # GET /api/v1/product_bundles
  def index
    @product_bundles = ProductBundle.active
                                    .includes(:products, :product_bundle_items)
                                    .order(created_at: :desc)

    # Filter by product if provided
    if params[:product_id].present?
      @product_bundles = @product_bundles.for_product(params[:product_id])
    end

    # Filter by bundle type
    if params[:bundle_type].present?
      @product_bundles = @product_bundles.where(bundle_type: params[:bundle_type])
    end

    render json: @product_bundles.as_json(
      include: {
        products: { only: [:id, :name, :daily_price_cents] },
        product_bundle_items: { include: { product: { only: [:id, :name] } } }
      }
    )
  end

  # GET /api/v1/product_bundles/:id
  def show
    render json: @product_bundle.as_json(
      include: {
        products: { only: [:id, :name, :daily_price_cents, :barcode] },
        product_bundle_items: {
          include: { product: { only: [:id, :name, :barcode, :daily_price_cents] } }
        }
      }
    )
  end

  # POST /api/v1/product_bundles
  def create
    @product_bundle = ProductBundle.new(product_bundle_params)

    if @product_bundle.save
      render json: @product_bundle, status: :created
    else
      render json: { errors: @product_bundle.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/product_bundles/:id
  def update
    if @product_bundle.update(product_bundle_params)
      render json: @product_bundle
    else
      render json: { errors: @product_bundle.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/product_bundles/:id
  def destroy
    @product_bundle.update(deleted: true)
    head :no_content
  end

  # GET /api/v1/product_bundles/check_requirements
  # Check if a set of products satisfies bundle requirements
  def check_requirements
    product_ids = params[:product_ids]&.map(&:to_i) || []

    violations = []
    ProductBundle.active.enforced.each do |bundle|
      missing = bundle.missing_required_products(product_ids)
      if missing.any?
        violations << {
          bundle: bundle,
          missing_product_ids: missing
        }
      end
    end

    render json: {
      valid: violations.empty?,
      violations: violations.as_json(include: :products)
    }
  end

  # GET /api/v1/product_bundles/suggestions
  # Get suggested bundles for a product
  def suggestions
    product_id = params[:product_id]
    product = Product.find(product_id)

    suggestions = {
      must_rent_with: product.must_rent_with.map { |p| { id: p.id, name: p.name } },
      cross_sell: product.cross_sell_products.map { |p| { id: p.id, name: p.name } },
      upsell: product.upsell_products.map { |p| { id: p.id, name: p.name } },
      frequently_together: product.frequently_rented_with.map { |p| { id: p.id, name: p.name } }
    }

    render json: suggestions
  end

  private

  def set_product_bundle
    @product_bundle = ProductBundle.find(params[:id])
  end

  def product_bundle_params
    params.require(:product_bundle).permit(
      :name,
      :description,
      :bundle_type,
      :enforce_bundling,
      :discount_percentage,
      :active,
      product_bundle_items_attributes: [
        :id,
        :product_id,
        :quantity,
        :required,
        :position,
        :_destroy
      ]
    )
  end
end
