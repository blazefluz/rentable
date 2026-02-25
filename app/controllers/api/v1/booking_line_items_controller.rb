# app/controllers/api/v1/booking_line_items_controller.rb
module Api
  module V1
    class BookingLineItemsController < ApplicationController
      before_action :set_booking
      before_action :set_line_item, only: [
        :update, :advance_workflow, :set_workflow, :destroy,
        :schedule_delivery, :advance_delivery, :mark_ready, :mark_out_for_delivery,
        :complete_delivery, :fail_delivery, :cancel_delivery, :capture_signature, :delivery_cost
      ]

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

      # POST /api/v1/bookings/:booking_id/line_items/:id/schedule_delivery
      def schedule_delivery
        if @line_item.schedule_delivery!(
          start_date: params[:start_date],
          end_date: params[:end_date],
          method: params[:method],
          cost: params[:cost]&.to_f,
          notes: params[:notes]
        )
          render json: {
            success: true,
            message: 'Delivery scheduled successfully',
            line_item: line_item_json(@line_item)
          }
        else
          render json: {
            success: false,
            errors: @line_item.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/bookings/:booking_id/line_items/:id/advance_delivery
      def advance_delivery
        @line_item.advance_delivery_status!
        render json: {
          success: true,
          message: "Delivery status advanced to #{@line_item.delivery_status}",
          line_item: line_item_json(@line_item)
        }
      end

      # PATCH /api/v1/bookings/:booking_id/line_items/:id/mark_ready
      def mark_ready
        @line_item.mark_ready_for_delivery!
        render json: {
          success: true,
          message: 'Delivery marked as ready',
          line_item: line_item_json(@line_item)
        }
      end

      # PATCH /api/v1/bookings/:booking_id/line_items/:id/mark_out_for_delivery
      def mark_out_for_delivery
        @line_item.mark_out_for_delivery!(
          tracking: params[:tracking_number],
          carrier: params[:carrier]
        )
        render json: {
          success: true,
          message: 'Marked as out for delivery',
          line_item: line_item_json(@line_item)
        }
      end

      # POST /api/v1/bookings/:booking_id/line_items/:id/complete_delivery
      def complete_delivery
        signature_captured = params[:signature_captured] == 'true' || params[:signature_captured] == true
        @line_item.complete_delivery!(signature_captured: signature_captured)
        render json: {
          success: true,
          message: 'Delivery completed successfully',
          line_item: line_item_json(@line_item)
        }
      end

      # POST /api/v1/bookings/:booking_id/line_items/:id/fail_delivery
      def fail_delivery
        @line_item.fail_delivery!(reason: params[:reason])
        render json: {
          success: true,
          message: 'Delivery marked as failed',
          line_item: line_item_json(@line_item)
        }
      end

      # DELETE /api/v1/bookings/:booking_id/line_items/:id/cancel_delivery
      def cancel_delivery
        @line_item.cancel_delivery!(reason: params[:reason])
        render json: {
          success: true,
          message: 'Delivery cancelled',
          line_item: line_item_json(@line_item)
        }
      end

      # POST /api/v1/bookings/:booking_id/line_items/:id/capture_signature
      def capture_signature
        if @line_item.capture_signature!
          render json: {
            success: true,
            message: 'Signature captured',
            line_item: line_item_json(@line_item)
          }
        else
          render json: {
            success: false,
            message: 'Signature not required or already captured'
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/bookings/:booking_id/line_items/:id/delivery_cost
      def delivery_cost
        cost = @line_item.calculate_delivery_cost
        render json: {
          cost: cost.format,
          cost_cents: cost.cents,
          currency: cost.currency.to_s,
          method: @line_item.delivery_method
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
