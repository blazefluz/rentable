class Api::V1::ProductVariantsController < ApplicationController
  before_action :set_product, only: [:index, :create, :bulk_create]
  before_action :set_variant, only: [:show, :update, :destroy, :adjust_stock, :reserve, :release]

  # GET /api/v1/products/:product_id/variants
  def index
    variants = @product.product_variants
                       .includes(:variant_options)
                       .active
                       .by_position

    render json: {
      product: {
        id: @product.id,
        name: @product.name,
        has_variants: @product.has_variants?
      },
      variants: variants.map { |v| variant_json(v) },
      meta: {
        total: variants.count,
        in_stock_count: variants.in_stock.count,
        out_of_stock_count: variants.out_of_stock.count,
        low_stock_count: variants.low_stock.count
      }
    }
  end

  # GET /api/v1/variants/:id
  def show
    render json: variant_json(@variant, include_history: true)
  end

  # POST /api/v1/products/:product_id/variants
  def create
    @product.enable_variants! unless @product.has_variants?

    variant = @product.product_variants.build(variant_params)
    variant.company = current_company

    if variant.save
      render json: variant_json(variant), status: :created
    else
      render json: { errors: variant.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/products/:product_id/variants/bulk_create
  # Create multiple variants from a matrix of options
  def bulk_create
    creator = BulkVariantCreator.new(@product)

    if params[:matrix].present?
      # Matrix mode: generate combinations
      success = creator.create_matrix(
        options: bulk_params[:options].to_h,
        base_price_cents: bulk_params[:base_price_cents],
        stock_quantity: bulk_params[:stock_quantity] || 0,
        user: current_user,
        **bulk_params.except(:options, :base_price_cents, :stock_quantity)
      )
    elsif params[:combinations].present?
      # Combinations mode: explicit combinations
      success = creator.create_from_combinations(
        combinations: bulk_params[:combinations],
        base_price_cents: bulk_params[:base_price_cents],
        stock_quantity: bulk_params[:stock_quantity] || 0,
        user: current_user
      )
    else
      return render json: { error: 'Must provide either matrix or combinations' }, status: :bad_request
    end

    if success
      render json: {
        message: "Successfully created #{creator.created_variants.count} variants",
        variants: creator.created_variants.map { |v| variant_json(v) },
        product: {
          id: @product.id,
          has_variants: @product.reload.has_variants?
        }
      }, status: :created
    else
      render json: {
        message: 'Failed to create some variants',
        errors: creator.errors
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/products/:product_id/variants/preview
  # Preview what variants would be created (dry run)
  def preview
    creator = BulkVariantCreator.new(@product)
    preview = creator.preview_matrix(options: params[:options].to_h)

    render json: preview
  end

  # PATCH /api/v1/variants/:id
  def update
    if @variant.update(variant_params)
      render json: variant_json(@variant)
    else
      render json: { errors: @variant.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/variants/:id
  def destroy
    if @variant.soft_delete!
      render json: { message: 'Variant deleted successfully' }
    else
      render json: { errors: @variant.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/variants/:id/adjust_stock
  def adjust_stock
    new_quantity = params[:quantity].to_i
    reason = params[:reason] || 'Manual adjustment'

    begin
      @variant.adjust_stock!(new_quantity, user: current_user, reason: reason)
      render json: {
        message: 'Stock adjusted successfully',
        variant: variant_json(@variant, include_history: true)
      }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/variants/:id/reserve
  def reserve
    quantity = params[:quantity].to_i
    reason = params[:reason]
    booking_id = params[:booking_id]

    begin
      booking = Booking.find(booking_id) if booking_id.present?
      @variant.reserve!(quantity, user: current_user, booking: booking, reason: reason)

      render json: {
        message: "Reserved #{quantity} units",
        variant: variant_json(@variant)
      }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/variants/:id/release
  def release
    quantity = params[:quantity].to_i
    reason = params[:reason]
    booking_id = params[:booking_id]

    begin
      booking = Booking.find(booking_id) if booking_id.present?
      @variant.release!(quantity, user: current_user, booking: booking, reason: reason)

      render json: {
        message: "Released #{quantity} units",
        variant: variant_json(@variant)
      }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/variants/:id/restock
  def restock
    quantity = params[:quantity].to_i
    reason = params[:reason]

    begin
      @variant.restock!(quantity, user: current_user, reason: reason)
      render json: {
        message: "Restocked #{quantity} units",
        variant: variant_json(@variant, include_history: true)
      }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/variants/:id/damage
  def damage
    quantity = params[:quantity].to_i
    reason = params[:reason] || 'Damaged'
    metadata = params[:metadata] || {}

    begin
      @variant.record_damage!(quantity, user: current_user, reason: reason, metadata: metadata)
      render json: {
        message: "Recorded damage for #{quantity} units",
        variant: variant_json(@variant, include_history: true)
      }
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  end

  def set_variant
    @variant = ProductVariant.find(params[:id])
  end

  def current_company
    # This should be set by your authentication/tenant middleware
    ActsAsTenant.current_tenant || current_user&.company
  end

  def variant_params
    params.require(:variant).permit(
      :variant_name,
      :price_cents,
      :price_currency,
      :compare_at_price_cents,
      :stock_quantity,
      :reserved_quantity,
      :low_stock_threshold,
      :position,
      :active,
      :featured,
      :weight,
      :barcode,
      dimensions: {},
      custom_attributes: {},
      variant_options_attributes: [:id, :option_name, :option_value, :position, :_destroy, metadata: {}]
    )
  end

  def bulk_params
    params.permit(
      :base_price_cents,
      :stock_quantity,
      :low_stock_threshold,
      :active,
      :featured,
      options: {},
      combinations: [{}]
    )
  end

  def variant_json(variant, include_history: false)
    json = {
      id: variant.id,
      product_id: variant.product_id,
      sku: variant.sku,
      barcode: variant.barcode,
      variant_name: variant.variant_name,
      display_name: variant.display_name,
      price: {
        cents: variant.price_cents,
        currency: variant.price_currency,
        formatted: variant.effective_price.format
      },
      compare_at_price: {
        cents: variant.compare_at_price_cents,
        currency: variant.price_currency,
        formatted: variant.compare_at_price&.format
      },
      has_discount: variant.has_discount?,
      discount_percentage: variant.discount_percentage,
      stock: {
        quantity: variant.stock_quantity,
        reserved: variant.reserved_quantity,
        available: variant.available_quantity,
        low_stock_threshold: variant.low_stock_threshold,
        in_stock: variant.in_stock?,
        low_stock: variant.low_stock?
      },
      position: variant.position,
      active: variant.active,
      featured: variant.featured,
      weight: variant.weight,
      dimensions: variant.dimensions,
      custom_attributes: variant.custom_attributes,
      options: variant.variant_options.by_position.map do |opt|
        {
          name: opt.option_name,
          value: opt.option_value,
          display: opt.display_text,
          metadata: opt.metadata
        }
      end,
      created_at: variant.created_at,
      updated_at: variant.updated_at
    }

    if include_history
      json[:stock_history] = variant.variant_stock_histories.recent.limit(20).map do |history|
        {
          id: history.id,
          change_type: history.change_type,
          quantity_before: history.quantity_before,
          quantity_after: history.quantity_after,
          quantity_change: history.quantity_change,
          change_description: history.change_description,
          user: history.user_name,
          reason: history.reason,
          reference: history.reference_display,
          created_at: history.created_at
        }
      end
    end

    json
  end
end
