# app/controllers/api/v1/payments_controller.rb
module Api
  module V1
    class PaymentsController < ApplicationController
      before_action :set_booking, only: [:index, :create, :destroy]
      before_action :set_payment, only: [:show, :update, :destroy]

      # GET /api/v1/payments (all payments)
      # GET /api/v1/bookings/:booking_id/payments (booking payments)
      def index
        if params[:booking_id]
          # Nested route - payments for a specific booking
          @payments = @booking.payments.active
                             .order(payment_date: :desc)
        else
          # Standalone route - all payments
          @payments = Payment.includes(:booking)
                            .active
                            .order(payment_date: :desc)
                            .page(params[:page])
                            .per(params[:per_page] || 25)

          # Filter by type
          @payments = @payments.by_type(params[:payment_type]) if params[:payment_type].present?

          # Filter by date range
          if params[:start_date].present? && params[:end_date].present?
            @payments = @payments.by_date_range(
              Date.parse(params[:start_date]),
              Date.parse(params[:end_date])
            )
          end
        end

        render json: {
          payments: @payments.map { |p| payment_json(p) },
          meta: params[:booking_id] ? {} : pagination_meta(@payments)
        }
      end

      # GET /api/v1/payments/:id
      def show
        render json: {
          payment: payment_detail_json(@payment)
        }
      end

      # POST /api/v1/bookings/:booking_id/payments
      def create
        @payment = @booking.payments.new(payment_params)

        if @payment.save
          # Recalculate booking total
          @booking.save

          render json: {
            payment: payment_detail_json(@payment),
            booking_balance: @booking.balance_due,
            message: "Payment created successfully"
          }, status: :created
        else
          render json: {
            errors: @payment.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/payments/:id
      def update
        if @payment.update(payment_params)
          render json: {
            payment: payment_detail_json(@payment),
            message: "Payment updated successfully"
          }
        else
          render json: {
            errors: @payment.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/bookings/:booking_id/payments/:id
      def destroy
        @payment.soft_delete!
        render json: {
          message: "Payment deleted successfully",
          booking_balance: @booking.balance_due
        }
      end

      private

      def set_booking
        @booking = Booking.find(params[:booking_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Booking not found" }, status: :not_found
      end

      def set_payment
        if params[:booking_id]
          @booking = Booking.find(params[:booking_id])
          @payment = @booking.payments.find(params[:id])
        else
          @payment = Payment.find(params[:id])
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Payment not found" }, status: :not_found
      end

      def payment_params
        params.require(:payment).permit(
          :amount_cents, :amount_currency, :payment_type,
          :quantity, :reference, :payment_date,
          :supplier, :payment_method, :comment
        )
      end

      def payment_json(payment)
        {
          id: payment.id,
          booking_id: payment.booking_id,
          booking_reference: payment.booking.reference_number,
          payment_type: payment.payment_type,
          amount: {
            amount: payment.amount_cents,
            currency: payment.amount_currency,
            formatted: payment.amount.format
          },
          quantity: payment.quantity,
          reference: payment.reference,
          payment_date: payment.payment_date,
          payment_method: payment.payment_method,
          supplier: payment.supplier,
          created_at: payment.created_at,
          updated_at: payment.updated_at
        }
      end

      def payment_detail_json(payment)
        payment_json(payment).merge({
          comment: payment.comment,
          booking: {
            id: payment.booking.id,
            reference_number: payment.booking.reference_number,
            customer_name: payment.booking.customer_name,
            total_price: {
              amount: payment.booking.total_price_cents,
              currency: payment.booking.total_price_currency,
              formatted: payment.booking.total_price.format
            },
            balance_due: payment.booking.balance_due
          }
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
