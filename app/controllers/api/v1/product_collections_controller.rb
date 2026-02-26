class Api::V1::ProductCollectionsController < ApplicationController
  before_action :set_collection, only: [:show, :update, :destroy, :add_product, :remove_product, :reorder, :analytics, :refresh]

  # GET /api/v1/product_collections
  def index
    @collections = ProductCollection.all

    # Filter by visibility
    @collections = @collections.where(visibility: params[:visibility]) if params[:visibility]

    # Filter by collection type
    @collections = @collections.by_type(params[:type]) if params[:type]

    # Filter by active status
    @collections = @collections.active if params[:active] == 'true'

    # Filter by featured
    @collections = @collections.featured_collections if params[:featured] == 'true'

    # Filter by root collections only
    @collections = @collections.root_collections if params[:root_only] == 'true'

    # Filter by parent
    @collections = @collections.where(parent_collection_id: params[:parent_id]) if params[:parent_id]

    # Filter by dynamic/static
    @collections = @collections.dynamic if params[:dynamic] == 'true'
    @collections = @collections.static if params[:static] == 'true'

    # Filter by current/expired/upcoming
    @collections = @collections.current if params[:current] == 'true'
    @collections = @collections.expired if params[:expired] == 'true'
    @collections = @collections.upcoming if params[:upcoming] == 'true'

    # Search by name
    @collections = @collections.where('name ILIKE ?', "%#{params[:search]}%") if params[:search]

    # Ordering
    case params[:sort_by]
    when 'name'
      @collections = @collections.order(name: params[:sort_order] || :asc)
    when 'position'
      @collections = @collections.order(position: params[:sort_order] || :asc)
    when 'created_at'
      @collections = @collections.order(created_at: params[:sort_order] || :desc)
    when 'product_count'
      @collections = @collections.order(product_count: params[:sort_order] || :desc)
    when 'views'
      @collections = @collections.left_joins(:collection_views)
                                  .group(:id)
                                  .order("COUNT(collection_views.id) #{params[:sort_order] || 'DESC'}")
    else
      @collections = @collections.order(position: :asc)
    end

    # Pagination
    page = params[:page] || 1
    per_page = params[:per_page] || 20
    @collections = @collections.page(page).per(per_page)

    render json: @collections, include: [:subcollections]
  end

  # GET /api/v1/product_collections/:id
  def show
    # Track view
    if params[:session_id]
      @collection.record_view!(
        session_id: params[:session_id],
        ip_address: request.remote_ip,
        user_agent: request.user_agent,
        referrer: request.referer,
        user: current_user
      )
    end

    render json: @collection, include: [:products, :subcollections, :parent_collection]
  end

  # POST /api/v1/product_collections
  def create
    @collection = ProductCollection.new(collection_params)

    if @collection.save
      render json: @collection, status: :created
    else
      render json: { errors: @collection.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/product_collections/:id
  def update
    if @collection.update(collection_params)
      render json: @collection
    else
      render json: { errors: @collection.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/product_collections/:id
  def destroy
    @collection.destroy
    head :no_content
  end

  # POST /api/v1/product_collections/:id/add_product
  def add_product
    product = Product.find(params[:product_id])

    begin
      item = @collection.add_product(
        product,
        position: params[:position],
        featured: params[:featured] || false,
        notes: params[:notes]
      )
      render json: { collection: @collection, item: item }, status: :created
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/product_collections/:id/remove_product
  def remove_product
    product = Product.find(params[:product_id])
    @collection.remove_product(product)
    render json: @collection
  end

  # PATCH /api/v1/product_collections/:id/reorder
  def reorder
    # Expects params[:items] = [{ id: item_id, position: new_position }, ...]
    items = params[:items] || []

    ProductCollection.transaction do
      items.each do |item_data|
        item = @collection.product_collection_items.find(item_data[:id])
        item.update!(position: item_data[:position])
      end
    end

    render json: @collection.reload
  end

  # GET /api/v1/product_collections/featured
  def featured
    @collections = ProductCollection.featured_collections
    render json: @collections
  end

  # GET /api/v1/product_collections/:id/analytics
  def analytics
    analytics_data = {
      collection: {
        id: @collection.id,
        name: @collection.name,
        slug: @collection.slug
      },
      views: {
        total: @collection.views_count,
        unique: @collection.unique_views_count,
        last_30_days: @collection.views_last_30_days
      },
      products: {
        count: @collection.products.count,
        popular: @collection.popular_products(5).map { |p| { id: p.id, name: p.name, popularity_score: p.popularity_score } }
      },
      performance: {
        conversion_rate: @collection.conversion_rate,
        total_revenue: @collection.total_revenue
      },
      hierarchy: {
        breadcrumb: @collection.breadcrumb_path,
        depth: @collection.depth,
        subcollections_count: @collection.subcollections.count
      }
    }

    render json: analytics_data
  end

  # POST /api/v1/product_collections/:id/refresh
  def refresh
    unless @collection.dynamic?
      return render json: { error: 'Collection is not dynamic' }, status: :unprocessable_entity
    end

    @collection.refresh_dynamic_products
    render json: {
      message: 'Collection refreshed successfully',
      product_count: @collection.products.count
    }
  end

  private

  def set_collection
    @collection = ProductCollection.find(params[:id])
  end

  def collection_params
    params.require(:product_collection).permit(
      :name, :slug, :description, :short_description, :visibility,
      :collection_type, :display_template, :active, :featured, :position,
      :parent_collection_id, :start_date, :end_date, :is_dynamic,
      :meta_title, :meta_description, :featured_image, :banner_image,
      rules: {},
      tags: []
    )
  end
end
