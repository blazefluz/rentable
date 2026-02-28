# app/controllers/api/v1/locations_controller.rb
module Api
  module V1
    class LocationsController < ApplicationController
      before_action :set_location, only: [:show, :update, :destroy, :archive, :unarchive]

      # GET /api/v1/locations
      def index
        @locations = Location.active
                             .includes(:client, :parent, :children)
                             .order(name: :asc)
                             .page(params[:page])
                             .per(params[:per_page] || 25)

        # Filter by client
        @locations = @locations.where(client_id: params[:client_id]) if params[:client_id].present?

        # Filter by parent (only root locations)
        @locations = @locations.root_locations if params[:root_only] == 'true'

        # Search by barcode
        @locations = @locations.by_barcode(params[:barcode]) if params[:barcode].present?

        render json: {
          locations: @locations.map { |l| location_json(l) },
          meta: pagination_meta(@locations)
        }
      end

      # GET /api/v1/locations/search_by_barcode/:barcode
      def search_by_barcode
        @location = Location.active.find_by(barcode: params[:barcode])

        if @location
          render json: { location: location_detail_json(@location) }
        else
          render json: { error: 'Location not found' }, status: :not_found
        end
      end

      # GET /api/v1/locations/:id
      def show
        render json: {
          location: location_detail_json(@location)
        }
      end

      # POST /api/v1/locations
      def create
        @location = Location.new(location_params)

        if @location.save
          render json: {
            location: location_detail_json(@location),
            message: "Location created successfully"
          }, status: :created
        else
          render json: {
            errors: @location.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/locations/:id
      def update
        if @location.update(location_params)
          render json: {
            location: location_detail_json(@location),
            message: "Location updated successfully"
          }
        else
          render json: {
            errors: @location.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/locations/:id
      def destroy
        @location.soft_delete!
        render json: {
          message: "Location deleted successfully"
        }
      end

      # POST /api/v1/locations/:id/archive
      def archive
        @location.archive!
        render json: {
          location: location_json(@location),
          message: "Location archived"
        }
      end

      # POST /api/v1/locations/:id/unarchive
      def unarchive
        @location.unarchive!
        render json: {
          location: location_json(@location),
          message: "Location unarchived"
        }
      end

      private

      def set_location
        @location = Location.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Location not found" }, status: :not_found
      end

      def location_params
        params.require(:location).permit(
          :name, :address, :notes, :client_id, :parent_id, :barcode
        )
      end

      def location_json(location)
        {
          id: location.id,
          name: location.name,
          full_path: location.full_path,
          client_id: location.client_id,
          client_name: location.client&.name,
          parent_id: location.parent_id,
          parent_name: location.parent&.name,
          archived: location.archived,
          has_children: location.children.any?,
          created_at: location.created_at,
          updated_at: location.updated_at
        }
      end

      def location_detail_json(location)
        location_json(location).merge({
          address: location.address,
          notes: location.notes,
          children: location.children.map { |c| { id: c.id, name: c.name, full_path: c.full_path } },
          stored_products_count: location.stored_products.count,
          venue_bookings_count: location.venue_bookings.count
        })
      end

    end
  end
end
