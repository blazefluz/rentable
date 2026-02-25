# app/controllers/api/v1/products_controller.rb
module Api
  module V1
    class ProductsController < ApplicationController
      before_action :set_product, only: [:show, :update, :destroy, :availability]

      # GET /api/v1/products
      def index
        @products = Product.active
                          .search(params[:query])
                          .by_category(params[:category])
                          .order(created_at: :desc)
                          .page(params[:page])
                          .per(params[:per_page] || 25)

        render json: {
          products: @products.map { |p| product_json(p) },
          meta: pagination_meta(@products)
        }
      end

      # GET /api/v1/products/:id
      def show
        render json: {
          product: product_detail_json(@product)
        }
      end

      # POST /api/v1/products
      def create
        @product = Product.new(product_params)

        if @product.save
          render json: {
            product: product_detail_json(@product),
            message: "Product created successfully"
          }, status: :created
        else
          render json: {
            errors: @product.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/products/:id
      def update
        if @product.update(product_params)
          render json: {
            product: product_detail_json(@product),
            message: "Product updated successfully"
          }
        else
          render json: {
            errors: @product.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/products/:id
      def destroy
        @product.update(active: false)
        render json: {
          message: "Product archived successfully"
        }
      end

      # GET /api/v1/products/:id/availability
      def availability
        start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today
        end_date = params[:end_date] ? Date.parse(params[:end_date]) : start_date + 7.days

        checker = AvailabilityChecker.new(@product, start_date, end_date)

        render json: {
          product_id: @product.id,
          product_name: @product.name,
          total_quantity: @product.quantity,
          available_quantity: checker.available_quantity,
          is_available: checker.available?,
          date_range: {
            start: start_date,
            end: end_date
          },
          availability_by_date: checker.availability_by_date
        }
      end

      private

      def set_product
        @product = Product.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Product not found" }, status: :not_found
      end

      def product_params
        params.require(:product).permit(
          :name, :description, :category, :barcode,
          :daily_price_cents, :daily_price_currency,
          :quantity, :active, serial_numbers: [], images: []
        )
      end

      def product_json(product)
        {
          id: product.id,
          name: product.name,
          description: product.description,
          category: product.category,
          daily_price: {
            amount: product.daily_price_cents,
            currency: product.daily_price_currency,
            formatted: product.daily_price.format
          },
          quantity: product.quantity,
          active: product.active,
          barcode: product.barcode,
          created_at: product.created_at,
          updated_at: product.updated_at
        }
      end

      def product_detail_json(product)
        product_json(product).merge({
          serial_numbers: product.serial_numbers,
          images: product.images.attached? ? product.images.map { |img| rails_blob_url(img) } : []
        })
      end

      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          next_page: collection.next_page,
          prev_page: collection.prev_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count
        }
      end
    end
  end
end
