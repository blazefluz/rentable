# app/controllers/api/v1/manufacturers_controller.rb
module Api
  module V1
    class ManufacturersController < ApplicationController
      before_action :set_manufacturer, only: [:show, :update, :destroy]

      # GET /api/v1/manufacturers
      def index
        @manufacturers = Manufacturer.includes(:product_types)
                                    .order(name: :asc)
                                    .page(params[:page])
                                    .per(params[:per_page] || 25)

        # Filter by search query
        @manufacturers = @manufacturers.search(params[:query]) if params[:query].present?

        render json: {
          manufacturers: @manufacturers.map { |m| manufacturer_json(m) },
          meta: pagination_meta(@manufacturers)
        }
      end

      # GET /api/v1/manufacturers/:id
      def show
        render json: {
          manufacturer: manufacturer_detail_json(@manufacturer)
        }
      end

      # POST /api/v1/manufacturers
      def create
        @manufacturer = Manufacturer.new(manufacturer_params)

        if @manufacturer.save
          render json: {
            manufacturer: manufacturer_detail_json(@manufacturer),
            message: "Manufacturer created successfully"
          }, status: :created
        else
          render json: {
            errors: @manufacturer.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/manufacturers/:id
      def update
        if @manufacturer.update(manufacturer_params)
          render json: {
            manufacturer: manufacturer_detail_json(@manufacturer),
            message: "Manufacturer updated successfully"
          }
        else
          render json: {
            errors: @manufacturer.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/manufacturers/:id
      def destroy
        @manufacturer.destroy
        render json: {
          message: "Manufacturer deleted successfully"
        }
      end

      private

      def set_manufacturer
        @manufacturer = Manufacturer.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Manufacturer not found" }, status: :not_found
      end

      def manufacturer_params
        params.require(:manufacturer).permit(
          :name, :website, :notes
        )
      end

      def manufacturer_json(manufacturer)
        {
          id: manufacturer.id,
          name: manufacturer.name,
          website: manufacturer.website,
          product_types_count: manufacturer.product_types.count,
          created_at: manufacturer.created_at,
          updated_at: manufacturer.updated_at
        }
      end

      def manufacturer_detail_json(manufacturer)
        manufacturer_json(manufacturer).merge({
          notes: manufacturer.notes,
          product_types: manufacturer.product_types.map do |pt|
            {
              id: pt.id,
              name: pt.name,
              category: pt.category,
              daily_price: {
                amount: pt.daily_price_cents,
                currency: pt.daily_price_currency,
                formatted: pt.daily_price.format
              }
            }
          end
        })
      end

    end
  end
end
