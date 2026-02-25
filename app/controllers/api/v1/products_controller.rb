# app/controllers/api/v1/products_controller.rb
module Api
  module V1
    class ProductsController < ApplicationController
      before_action :set_product, only: [:show, :update, :destroy, :availability, :attach_images, :remove_image, :transfer, :archive, :unarchive]

      # GET /api/v1/products
      def index
        @products = Product.includes(:product_type, :storage_location).all

        # Active/inactive filter
        @products = @products.where(active: true, deleted: false) unless params[:include_inactive] == 'true'

        # Archived filter
        @products = @products.where(archived: false) unless params[:include_archived] == 'true'

        # Search filter
        @products = @products.search(params[:query]) if params[:query].present?

        # Category filter
        @products = @products.by_category(params[:category]) if params[:category].present?

        # Price range filter
        if params[:min_price].present?
          min_cents = (params[:min_price].to_f * 100).to_i
          @products = @products.where('daily_price_cents >= ?', min_cents)
        end
        if params[:max_price].present?
          max_cents = (params[:max_price].to_f * 100).to_i
          @products = @products.where('daily_price_cents <= ?', max_cents)
        end

        # Quantity filter (minimum available quantity)
        if params[:min_quantity].present?
          @products = @products.where('quantity >= ?', params[:min_quantity].to_i)
        end

        # Sorting
        sort_by = params[:sort_by] || 'created_at'
        sort_order = params[:sort_order] || 'desc'

        case sort_by
        when 'name'
          @products = @products.order(name: sort_order)
        when 'price'
          @products = @products.order(daily_price_cents: sort_order)
        when 'quantity'
          @products = @products.order(quantity: sort_order)
        when 'category'
          @products = @products.order(category: sort_order, name: :asc)
        else
          @products = @products.order(created_at: sort_order)
        end

        @products = @products.page(params[:page]).per(params[:per_page] || 25)

        render json: {
          products: @products.map { |p| product_json(p) },
          meta: pagination_meta(@products),
          filters_applied: {
            query: params[:query],
            category: params[:category],
            min_price: params[:min_price],
            max_price: params[:max_price],
            min_quantity: params[:min_quantity],
            sort_by: sort_by,
            sort_order: sort_order
          }
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

      # POST /api/v1/products/:id/attach_images
      def attach_images
        if params[:images].present?
          @product.images.attach(params[:images])
          render json: {
            message: "Images attached successfully",
            images: @product.images.map { |img| { id: img.id, url: rails_blob_url(img) } }
          }
        else
          render json: { error: "No images provided" }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/products/:id/remove_image/:image_id
      def remove_image
        image = @product.images.find(params[:image_id])
        image.purge
        render json: { message: "Image removed successfully" }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Image not found" }, status: :not_found
      end

      # GET /api/v1/products/search_by_barcode/:barcode
      def search_by_barcode
        @product = Product.includes(:product_type, :storage_location)
                         .find_by(barcode: params[:barcode])

        if @product
          render json: {
            product: product_detail_json(@product),
            found: true
          }
        else
          render json: {
            found: false,
            message: "No product found with barcode: #{params[:barcode]}"
          }, status: :not_found
        end
      end

      # POST /api/v1/products/:id/transfer
      def transfer
        new_location = Location.find(params[:location_id])

        old_location = @product.storage_location
        @product.update!(storage_location: new_location)

        render json: {
          message: "Product transferred successfully",
          product: product_json(@product),
          transfer: {
            from: old_location ? { id: old_location.id, name: old_location.name, full_path: old_location.full_path } : nil,
            to: { id: new_location.id, name: new_location.name, full_path: new_location.full_path }
          }
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Location not found" }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      # PATCH /api/v1/products/:id/archive
      def archive
        @product.update!(archived: true)
        render json: {
          message: "Product archived",
          product: product_json(@product)
        }
      end

      # PATCH /api/v1/products/:id/unarchive
      def unarchive
        @product.update!(archived: false)
        render json: {
          message: "Product unarchived",
          product: product_json(@product)
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
          :weekly_price_cents, :weekly_price_currency,
          :value_cents, :mass, :asset_tag,
          :product_type_id, :storage_location_id,
          :quantity, :active, :archived, :show_public, :end_date,
          serial_numbers: [], custom_fields: {}, images: []
        )
      end

      def product_json(product)
        {
          id: product.id,
          name: product.name,
          description: product.description,
          category: product.category,
          barcode: product.barcode,
          asset_tag: product.asset_tag,
          daily_price: {
            amount: product.daily_price_cents,
            currency: product.daily_price_currency,
            formatted: product.daily_price.format
          },
          weekly_price: {
            amount: product.weekly_price_cents,
            currency: product.weekly_price_currency,
            formatted: product.weekly_price.format
          },
          value: {
            amount: product.value_cents,
            currency: product.daily_price_currency,
            formatted: Money.new(product.value_cents, product.daily_price_currency).format
          },
          mass: product.mass,
          quantity: product.quantity,
          active: product.active,
          archived: product.archived,
          show_public: product.show_public,
          product_type: product.product_type ? {
            id: product.product_type_id,
            name: product.product_type.name,
            full_name: product.product_type.full_name
          } : nil,
          storage_location: product.storage_location ? {
            id: product.storage_location_id,
            name: product.storage_location.name,
            full_path: product.storage_location.full_path
          } : nil,
          created_at: product.created_at,
          updated_at: product.updated_at
        }
      end

      def product_detail_json(product)
        product_json(product).merge({
          serial_numbers: product.serial_numbers,
          custom_fields: product.custom_fields,
          end_date: product.end_date,
          images: product.images.attached? ? product.images.map { |img| rails_blob_url(img) } : [],
          product_type_detail: product.product_type ? {
            id: product.product_type.id,
            name: product.product_type.name,
            full_name: product.product_type.full_name,
            manufacturer: product.product_type.manufacturer&.name,
            category: product.product_type.category,
            description: product.product_type.description
          } : nil
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
