# app/controllers/api/v1/kits_controller.rb
module Api
  module V1
    class KitsController < ApplicationController
      before_action :set_kit, only: [:show, :update, :destroy, :availability, :attach_images, :remove_image]

      # GET /api/v1/kits
      def index
        @kits = Kit.active
                   .includes(kit_items: :product)
                   .order(created_at: :desc)
                   .page(params[:page])
                   .per(params[:per_page] || 25)

        render json: {
          kits: @kits.map { |k| kit_json(k) },
          meta: pagination_meta(@kits)
        }
      end

      # GET /api/v1/kits/:id
      def show
        render json: {
          kit: kit_detail_json(@kit)
        }
      end

      # POST /api/v1/kits
      def create
        @kit = Kit.new(kit_params)

        if @kit.save
          # Add kit items if provided
          if params[:kit_items].present?
            params[:kit_items].each do |item|
              @kit.kit_items.create!(
                product_id: item[:product_id],
                quantity: item[:quantity]
              )
            end
          end

          render json: {
            kit: kit_detail_json(@kit),
            message: "Kit created successfully"
          }, status: :created
        else
          render json: {
            errors: @kit.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/kits/:id
      def update
        if @kit.update(kit_params)
          # Update kit items if provided
          if params[:kit_items].present?
            @kit.kit_items.destroy_all
            params[:kit_items].each do |item|
              @kit.kit_items.create!(
                product_id: item[:product_id],
                quantity: item[:quantity]
              )
            end
          end

          render json: {
            kit: kit_detail_json(@kit),
            message: "Kit updated successfully"
          }
        else
          render json: {
            errors: @kit.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/kits/:id
      def destroy
        @kit.update(active: false)
        render json: {
          message: "Kit archived successfully"
        }
      end

      # GET /api/v1/kits/:id/availability
      def availability
        start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today
        end_date = params[:end_date] ? Date.parse(params[:end_date]) : start_date + 7.days
        requested_qty = params[:quantity]&.to_i || 1

        available_qty = @kit.available_quantity(start_date, end_date)
        is_available = @kit.available?(start_date, end_date, requested_qty)

        render json: {
          kit_id: @kit.id,
          kit_name: @kit.name,
          requested_quantity: requested_qty,
          available_quantity: available_qty,
          is_available: is_available,
          date_range: {
            start: start_date,
            end: end_date
          },
          component_availability: @kit.kit_items.map do |item|
            {
              product_id: item.product_id,
              product_name: item.product.name,
              required_quantity: item.quantity * requested_qty,
              available_quantity: item.product.available_quantity(start_date, end_date)
            }
          end
        }
      end

      # POST /api/v1/kits/:id/attach_images
      def attach_images
        if params[:images].present?
          @kit.images.attach(params[:images])
          render json: {
            message: "Images attached successfully",
            images: @kit.images.map { |img| { id: img.id, url: rails_blob_url(img) } }
          }
        else
          render json: { error: "No images provided" }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/kits/:id/remove_image/:image_id
      def remove_image
        image = @kit.images.find(params[:image_id])
        image.purge
        render json: { message: "Image removed successfully" }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Image not found" }, status: :not_found
      end

      private

      def set_kit
        @kit = Kit.includes(kit_items: :product).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Kit not found" }, status: :not_found
      end

      def kit_params
        params.require(:kit).permit(
          :name, :description,
          :daily_price_cents, :daily_price_currency,
          :active,
          kit_items_attributes: [:id, :product_id, :quantity, :_destroy],
          images: []
        )
      end

      def kit_json(kit)
        {
          id: kit.id,
          name: kit.name,
          description: kit.description,
          daily_price: {
            amount: kit.daily_price_cents,
            currency: kit.daily_price_currency,
            formatted: kit.daily_price.format
          },
          active: kit.active,
          items_count: kit.kit_items.count,
          kit_items: kit.kit_items.map do |item|
            {
              id: item.id,
              product_id: item.product_id,
              quantity: item.quantity
            }
          end,
          created_at: kit.created_at,
          updated_at: kit.updated_at
        }
      end

      def kit_detail_json(kit)
        kit_json(kit).merge({
          items: kit.kit_items.map do |item|
            {
              id: item.id,
              product: {
                id: item.product.id,
                name: item.product.name,
                category: item.product.category
              },
              quantity: item.quantity
            }
          end,
          images: kit.images.attached? ? kit.images.map { |img| rails_blob_url(img) } : []
        })
      end

    end
  end
end
