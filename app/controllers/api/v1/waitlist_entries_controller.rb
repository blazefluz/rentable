# app/controllers/api/v1/waitlist_entries_controller.rb
module Api
  module V1
    class WaitlistEntriesController < ApplicationController
      before_action :set_waitlist_entry, only: [:show, :update, :destroy, :notify, :fulfill]

      # GET /api/v1/waitlist_entries
      def index
        @entries = WaitlistEntry.includes(:bookable).order(created_at: :desc)

        # Filter by status
        @entries = @entries.where(status: params[:status]) if params[:status].present?

        # Filter by bookable
        if params[:product_id].present?
          @entries = @entries.for_product(params[:product_id])
        elsif params[:kit_id].present?
          @entries = @entries.for_kit(params[:kit_id])
        end

        # Filter by customer email
        @entries = @entries.where(customer_email: params[:customer_email]) if params[:customer_email].present?

        @entries = @entries.page(params[:page]).per(params[:per_page] || 25)

        render json: {
          waitlist_entries: @entries.map { |e| waitlist_entry_json(e) },
          meta: pagination_meta(@entries)
        }
      end

      # GET /api/v1/waitlist_entries/:id
      def show
        render json: {
          waitlist_entry: waitlist_entry_detail_json(@waitlist_entry)
        }
      end

      # POST /api/v1/waitlist_entries
      def create
        bookable_type = params[:bookable_type] # 'Product' or 'Kit'
        bookable_id = params[:bookable_id]

        bookable = bookable_type.constantize.find(bookable_id)

        @waitlist_entry = WaitlistEntry.new(waitlist_entry_params.merge(bookable: bookable))

        if @waitlist_entry.save
          render json: {
            waitlist_entry: waitlist_entry_detail_json(@waitlist_entry),
            message: "Added to waitlist successfully. We'll notify you when it becomes available."
          }, status: :created
        else
          render json: {
            errors: @waitlist_entry.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/waitlist_entries/:id
      def update
        if @waitlist_entry.update(waitlist_entry_params)
          render json: {
            waitlist_entry: waitlist_entry_detail_json(@waitlist_entry),
            message: "Waitlist entry updated successfully"
          }
        else
          render json: {
            errors: @waitlist_entry.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/waitlist_entries/:id
      def destroy
        @waitlist_entry.update(status: :cancelled)
        render json: {
          message: "Removed from waitlist"
        }
      end

      # PATCH /api/v1/waitlist_entries/:id/notify
      def notify
        @waitlist_entry.notify!
        # TODO: Send email notification
        # WaitlistMailer.availability_notification(@waitlist_entry).deliver_later

        render json: {
          waitlist_entry: waitlist_entry_json(@waitlist_entry),
          message: "Customer notified"
        }
      end

      # PATCH /api/v1/waitlist_entries/:id/fulfill
      def fulfill
        @waitlist_entry.fulfill!
        render json: {
          waitlist_entry: waitlist_entry_json(@waitlist_entry),
          message: "Waitlist entry marked as fulfilled"
        }
      end

      # GET /api/v1/waitlist_entries/check_fulfillable
      def check_fulfillable
        fulfillable_entries = WaitlistEntry.status_waiting.select(&:can_be_fulfilled?)

        render json: {
          count: fulfillable_entries.count,
          entries: fulfillable_entries.map { |e| waitlist_entry_json(e) }
        }
      end

      private

      def set_waitlist_entry
        @waitlist_entry = WaitlistEntry.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Waitlist entry not found" }, status: :not_found
      end

      def waitlist_entry_params
        params.require(:waitlist_entry).permit(
          :customer_name, :customer_email, :customer_phone,
          :start_date, :end_date, :quantity, :notes
        )
      end

      def waitlist_entry_json(entry)
        {
          id: entry.id,
          bookable: {
            type: entry.bookable_type,
            id: entry.bookable_id,
            name: entry.bookable.name
          },
          customer_name: entry.customer_name,
          customer_email: entry.customer_email,
          start_date: entry.start_date,
          end_date: entry.end_date,
          quantity: entry.quantity,
          status: entry.status,
          notified_at: entry.notified_at,
          can_be_fulfilled: entry.can_be_fulfilled?,
          created_at: entry.created_at
        }
      end

      def waitlist_entry_detail_json(entry)
        waitlist_entry_json(entry).merge({
          customer_phone: entry.customer_phone,
          notes: entry.notes,
          updated_at: entry.updated_at
        })
      end

    end
  end
end
