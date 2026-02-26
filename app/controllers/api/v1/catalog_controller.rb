class Api::V1::CatalogController < ApplicationController
  # Public catalog browsing - no authentication required
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  def index
    @products = Product.public_visible.active.available_for_rent
                       .includes(:product_type, :images)
                       .page(params[:page]).per(params[:per_page] || 20)

    if params[:category].present?
      @products = @products.by_category(params[:category])
    end

    if params[:product_type_id].present?
      @products = @products.by_product_type(params[:product_type_id])
    end

    render json: @products.as_json(
      include: {
        product_type: { only: [:id, :name, :category] }
      },
      methods: [:featured, :popularity_score],
      only: [:id, :name, :description, :category, :daily_price_cents, :daily_price_currency,
             :weekly_price_cents, :weekly_price_currency, :tags, :model_number, :specifications]
    )
  end

  def featured
    @products = Product.public_visible.active.featured.available_for_rent
                       .includes(:product_type, :images)
                       .limit(params[:limit] || 10)

    render json: @products.as_json(
      include: {
        product_type: { only: [:id, :name, :category] }
      },
      only: [:id, :name, :description, :category, :daily_price_cents, :daily_price_currency,
             :tags, :model_number]
    )
  end

  def popular
    @products = Product.public_visible.active.popular.available_for_rent
                       .includes(:product_type, :images)
                       .limit(params[:limit] || 10)

    render json: @products.as_json(
      include: {
        product_type: { only: [:id, :name, :category] }
      },
      methods: [:popularity_score],
      only: [:id, :name, :description, :category, :daily_price_cents, :daily_price_currency,
             :tags, :model_number]
    )
  end

  def search
    query = params[:q]

    if query.blank?
      render json: { error: 'Search query is required' }, status: :bad_request
      return
    end

    @products = Product.public_visible.active.search_advanced(query)
                       .includes(:product_type, :images)
                       .page(params[:page]).per(params[:per_page] || 20)

    # Filter by tags if provided
    if params[:tags].present?
      tags = params[:tags].is_a?(Array) ? params[:tags] : params[:tags].split(',')
      @products = @products.with_any_tags(tags)
    end

    # Filter by category if provided
    if params[:category].present?
      @products = @products.by_category(params[:category])
    end

    render json: {
      query: query,
      count: @products.total_count,
      products: @products.as_json(
        include: {
          product_type: { only: [:id, :name, :category] }
        },
        methods: [:featured, :popularity_score],
        only: [:id, :name, :description, :category, :daily_price_cents, :daily_price_currency,
               :tags, :model_number, :specifications]
      )
    }
  end

  def recommendations
    product_id = params[:product_id]

    if product_id.blank?
      render json: { error: 'Product ID is required' }, status: :bad_request
      return
    end

    product = Product.find(product_id)

    # Get recommendations based on:
    # 1. Same category
    # 2. Similar tags
    # 3. Frequently rented together (accessories)

    @recommendations = Product.public_visible.active.available_for_rent
                              .where.not(id: product_id)
                              .where(category: product.category)
                              .limit(params[:limit] || 5)

    # Add accessories as recommendations
    @accessories = product.suggested_accessories.select { |a| a.show_public && a.active }

    render json: {
      recommendations: @recommendations.as_json(
        only: [:id, :name, :description, :daily_price_cents, :daily_price_currency, :tags]
      ),
      suggested_accessories: @accessories.as_json(
        only: [:id, :name, :description, :daily_price_cents, :daily_price_currency]
      )
    }
  end
end
