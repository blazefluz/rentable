# app/controllers/api/v1/clients_controller.rb
module Api
  module V1
    class ClientsController < ApplicationController
      before_action :set_client, only: [:show, :update, :destroy, :archive, :unarchive]

      # GET /api/v1/clients
      def index
        @clients = Client.active
                        .order(name: :asc)
                        .page(params[:page])
                        .per(params[:per_page] || 25)

        # Filter by search query
        @clients = @clients.search(params[:query]) if params[:query].present?

        render json: {
          clients: @clients.map { |c| client_json(c) },
          meta: pagination_meta(@clients)
        }
      end

      # GET /api/v1/clients/:id
      def show
        render json: {
          client: client_detail_json(@client)
        }
      end

      # POST /api/v1/clients
      def create
        @client = Client.new(client_params)

        if @client.save
          render json: {
            client: client_detail_json(@client),
            message: "Client created successfully"
          }, status: :created
        else
          render json: {
            errors: @client.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/clients/:id
      def update
        if @client.update(client_params)
          render json: {
            client: client_detail_json(@client),
            message: "Client updated successfully"
          }
        else
          render json: {
            errors: @client.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/clients/:id
      def destroy
        @client.soft_delete!
        render json: {
          message: "Client deleted successfully"
        }
      end

      # POST /api/v1/clients/:id/archive
      def archive
        @client.archive!
        render json: {
          client: client_json(@client),
          message: "Client archived"
        }
      end

      # POST /api/v1/clients/:id/unarchive
      def unarchive
        @client.unarchive!
        render json: {
          client: client_json(@client),
          message: "Client unarchived"
        }
      end

      private

      def set_client
        @client = Client.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Client not found" }, status: :not_found
      end

      def client_params
        params.require(:client).permit(
          :name, :email, :phone, :website, :address, :notes
        )
      end

      def client_json(client)
        {
          id: client.id,
          name: client.name,
          email: client.email,
          phone: client.phone,
          website: client.website,
          archived: client.archived,
          created_at: client.created_at,
          updated_at: client.updated_at
        }
      end

      def client_detail_json(client)
        client_json(client).merge({
          address: client.address,
          notes: client.notes,
          bookings_count: client.bookings.count,
          locations_count: client.locations.count
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
