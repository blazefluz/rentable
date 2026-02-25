# app/controllers/api/v1/product_types_controller.rb
module Api
  module V1
    class ProductTypesController < ApplicationController
      before_action :set_product_type, only: [:show, :update, :destroy]

      # GET /api/v1/product_types
      def index
        @product_types = ProductType.includes(:manufacturer, :products)
                                    .order(name: :asc)
                                    .page(params[:page])
                                    .per(params[:per_page] || 25)

        # Filter by archived status
        @product_types = @product_types.active unless params[:include_archived] == 'true'
        @product_types = @product_types.archived if params[:archived] == 'true'

        # Filter by category
        @product_types = @product_types.by_category(params[:category]) if params[:category].present?

        # Filter by manufacturer
        @product_types = @product_types.where(manufacturer_id: params[:manufacturer_id]) if params[:manufacturer_id].present?

        # Search
        @product_types = @product_types.search(params[:query]) if params[:query].present?

        render json: {
          product_types: @product_types.map { |pt| product_type_json(pt) },
          meta: pagination_meta(@product_types)
        }
      end

      # GET /api/v1/product_types/:id
      def show
        render json: {
          product_type: product_type_detail_json(@product_type)
        }
      end

      # POST /api/v1/product_types
      def create
        @product_type = ProductType.new(product_type_params)

        if @product_type.save
          render json: {
            product_type: product_type_detail_json(@product_type),
            message: "Product type created successfully"
          }, status: :created
        else
          render json: {
            errors: @product_type.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/product_types/:id
      def update
        if @product_type.update(product_type_params)
          render json: {
            product_type: product_type_detail_json(@product_type),
            message: "Product type updated successfully"
          }
        else
          render json: {
            errors: @product_type.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/product_types/:id
      def destroy
        @product_type.destroy
        render json: {
          message: "Product type deleted successfully"
        }
      end

      private

      def set_product_type
        @product_type = ProductType.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Product type not found" }, status: :not_found
      end

      def product_type_params
        params.require(:product_type).permit(
          :name, :description, :category, :manufacturer_id,
          :daily_price_cents, :daily_price_currency,
          :weekly_price_cents, :weekly_price_currency,
          :value_cents, :mass, :product_link,
          :color, :discount_percentage, :archived,
          custom_fields: {}
        )
      end

      def product_type_json(product_type)
        {
          id: product_type.id,
          name: product_type.name,
          full_name: product_type.manufacturer ? product_type.full_name : product_type.name,
          category: product_type.category,
          color: product_type.color,
          discount_percentage: product_type.discount_percentage,
          archived: product_type.archived,
          manufacturer_id: product_type.manufacturer_id,
          manufacturer_name: product_type.manufacturer&.name,
          daily_price: {
            amount: product_type.daily_price_cents,
            currency: product_type.daily_price_currency,
            formatted: product_type.daily_price.format
          },
          weekly_price: {
            amount: product_type.weekly_price_cents,
            currency: product_type.weekly_price_currency,
            formatted: product_type.weekly_price.format
          },
          discounted_daily_price: {
            formatted: product_type.discounted_daily_price.format
          },
          discounted_weekly_price: {
            formatted: product_type.discounted_weekly_price.format
          },
          products_count: product_type.products.count,
          created_at: product_type.created_at,
          updated_at: product_type.updated_at
        }
      end

      def product_type_detail_json(product_type)
        product_type_json(product_type).merge({
          description: product_type.description,
          value: {
            amount: product_type.value_cents,
            currency: product_type.daily_price_currency,
            formatted: product_type.value.format
          },
          mass: product_type.mass,
          product_link: product_type.product_link,
          custom_fields: product_type.custom_fields,
          products: product_type.products.map do |p|
            {
              id: p.id,
              name: p.name,
              asset_tag: p.asset_tag,
              barcode: p.barcode,
              quantity: p.quantity,
              active: p.active
            }
          end
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
