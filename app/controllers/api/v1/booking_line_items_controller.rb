# app/controllers/api/v1/booking_line_items_controller.rb
module Api
  module V1
    class BookingLineItemsController < ApplicationController
      before_action :set_booking
      before_action :set_line_item, only: [:update, :advance_workflow, :set_workflow, :destroy]

      # PATCH /api/v1/bookings/:booking_id/line_items/:id
      def update
        if @line_item.update(line_item_params)
          render json: {
            line_item: line_item_json(@line_item),
            message: "Line item updated successfully"
          }
        else
          render json: {
            errors: @line_item.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/bookings/:booking_id/line_items/:id/advance_workflow
      def advance_workflow
        @line_item.advance_workflow!

        render json: {
          line_item: line_item_json(@line_item),
          message: "Workflow advanced to #{@line_item.workflow_status}"
        }
      end

      # PATCH /api/v1/bookings/:booking_id/line_items/:id/set_workflow
      def set_workflow
        if @line_item.update(workflow_status: params[:workflow_status])
          render json: {
            line_item: line_item_json(@line_item),
            message: "Workflow set to #{@line_item.workflow_status}"
          }
        else
          render json: {
            errors: @line_item.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/bookings/:booking_id/line_items/:id
      def destroy
        @line_item.soft_delete!
        render json: {
          message: "Line item removed successfully"
        }
      end

      private

      def set_booking
        @booking = Booking.find(params[:booking_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Booking not found" }, status: :not_found
      end

      def set_line_item
        @line_item = @booking.booking_line_items.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Line item not found" }, status: :not_found
      end

      def line_item_params
        params.require(:line_item).permit(
          :quantity, :discount_percent, :comment, :workflow_status
        )
      end

      def line_item_json(line_item)
        {
          id: line_item.id,
          bookable_type: line_item.bookable_type,
          bookable_id: line_item.bookable_id,
          bookable_name: line_item.bookable.name,
          quantity: line_item.quantity,
          days: line_item.days,
          workflow_status: line_item.workflow_status,
          discount_percent: line_item.discount_percent,
          comment: line_item.comment,
          price_per_day: {
            amount: line_item.price_cents,
            currency: line_item.price_currency,
            formatted: line_item.price.format
          },
          line_subtotal: {
            amount: line_item.line_subtotal.cents,
            currency: line_item.line_subtotal.currency.to_s,
            formatted: line_item.line_subtotal.format
          },
          line_total: {
            amount: line_item.line_total.cents,
            currency: line_item.line_total.currency.to_s,
            formatted: line_item.line_total.format
          },
          updated_at: line_item.updated_at
        }
      end
    end
  end
end
