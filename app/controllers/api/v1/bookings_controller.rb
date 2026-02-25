# app/controllers/api/v1/bookings_controller.rb
module Api
  module V1
    class BookingsController < ApplicationController
      before_action :set_booking, only: [:show, :update, :destroy, :confirm, :cancel, :complete, :archive, :unarchive, :extend]

      # GET /api/v1/bookings
      def index
        @bookings = Booking.includes(:booking_line_items, :client, :manager, :venue_location, :payments)
                          .not_deleted
                          .order(created_at: :desc)
                          .page(params[:page])
                          .per(params[:per_page] || 25)

        # Filter by status
        @bookings = @bookings.where(status: params[:status]) if params[:status].present?

        # Filter by client
        @bookings = @bookings.where(client_id: params[:client_id]) if params[:client_id].present?

        # Filter by manager
        @bookings = @bookings.where(manager_id: params[:manager_id]) if params[:manager_id].present?

        # Filter archived
        if params[:archived] == 'true'
          @bookings = @bookings.archived_records
        elsif params[:archived] == 'false'
          @bookings = @bookings.not_archived
        end

        render json: {
          bookings: @bookings.map { |b| booking_json(b) },
          meta: pagination_meta(@bookings)
        }
      end

      # GET /api/v1/bookings/:id
      def show
        render json: {
          booking: booking_detail_json(@booking)
        }
      end

      # POST /api/v1/bookings
      def create
        @booking = Booking.new(booking_params)

        # Add line items
        if params[:line_items].present?
          params[:line_items].each do |item|
            bookable = item[:bookable_type].constantize.find(item[:bookable_id])
            @booking.booking_line_items.build(
              bookable: bookable,
              quantity: item[:quantity]
            )
          end
        end

        if @booking.save
          render json: {
            booking: booking_detail_json(@booking),
            message: "Booking created successfully"
          }, status: :created
        else
          render json: {
            errors: @booking.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/bookings/:id
      def update
        if @booking.update(booking_params)
          render json: {
            booking: booking_detail_json(@booking),
            message: "Booking updated successfully"
          }
        else
          render json: {
            errors: @booking.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/bookings/:id
      def destroy
        @booking.soft_delete!
        render json: {
          message: "Booking deleted successfully"
        }
      end

      # PATCH /api/v1/bookings/:id/confirm
      def confirm
        if @booking.update(status: :confirmed)
          # Send confirmation email
          BookingMailer.confirmation(@booking).deliver_later

          render json: {
            booking: booking_detail_json(@booking),
            message: "Booking confirmed"
          }
        else
          render json: {
            errors: @booking.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/bookings/:id/cancel
      def cancel
        if @booking.update(status: :cancelled)
          render json: {
            booking: booking_detail_json(@booking),
            message: "Booking cancelled"
          }
        else
          render json: {
            errors: @booking.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/bookings/:id/complete
      def complete
        if @booking.update(status: :completed)
          render json: {
            booking: booking_detail_json(@booking),
            message: "Booking marked as completed"
          }
        else
          render json: {
            errors: @booking.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/bookings/:id/archive
      def archive
        @booking.archive!
        render json: {
          booking: booking_json(@booking),
          message: "Booking archived"
        }
      end

      # PATCH /api/v1/bookings/:id/unarchive
      def unarchive
        @booking.unarchive!
        render json: {
          booking: booking_json(@booking),
          message: "Booking unarchived"
        }
      end

      # PATCH /api/v1/bookings/:id/extend
      def extend
        new_end_date = params[:new_end_date] ? Date.parse(params[:new_end_date]) : nil

        if new_end_date.nil?
          return render json: { error: "new_end_date is required" }, status: :bad_request
        end

        if new_end_date <= @booking.end_date.to_date
          return render json: { error: "new_end_date must be after current end_date" }, status: :bad_request
        end

        # Check availability for the extension period
        availability_ok = @booking.booking_line_items.all? do |item|
          item.bookable.available?(@booking.end_date + 1.day, new_end_date, item.quantity)
        end

        unless availability_ok
          return render json: {
            error: "One or more items are not available for the extension period",
            suggestion: "Check availability for individual items"
          }, status: :unprocessable_entity
        end

        # Calculate additional cost
        extension_days = (new_end_date - @booking.end_date.to_date).to_i
        additional_cost_cents = @booking.booking_line_items.sum do |item|
          item.price_cents * item.quantity * extension_days
        end

        old_end_date = @booking.end_date
        @booking.end_date = new_end_date

        if @booking.save
          render json: {
            booking: booking_detail_json(@booking),
            extension: {
              old_end_date: old_end_date,
              new_end_date: new_end_date,
              additional_days: extension_days,
              additional_cost: {
                cents: additional_cost_cents,
                formatted: Money.new(additional_cost_cents, @booking.total_price_currency).format
              }
            },
            message: "Booking extended successfully"
          }
        else
          render json: {
            errors: @booking.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/bookings/check_availability
      def check_availability
        start_date = Date.parse(params[:start_date])
        end_date = Date.parse(params[:end_date])
        items = params[:items] || []

        availability_results = items.map do |item|
          bookable = item[:bookable_type].constantize.find(item[:bookable_id])
          quantity = item[:quantity].to_i

          {
            bookable_type: item[:bookable_type],
            bookable_id: item[:bookable_id],
            bookable_name: bookable.name,
            requested_quantity: quantity,
            available_quantity: bookable.available_quantity(start_date, end_date),
            is_available: bookable.available?(start_date, end_date, quantity)
          }
        end

        all_available = availability_results.all? { |r| r[:is_available] }

        render json: {
          date_range: {
            start: start_date,
            end: end_date
          },
          all_available: all_available,
          items: availability_results
        }
      rescue Date::Error
        render json: { error: "Invalid date format" }, status: :bad_request
      end

      private

      def set_booking
        @booking = Booking.includes(booking_line_items: :bookable).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Booking not found" }, status: :not_found
      end

      def booking_params
        params.require(:booking).permit(
          :start_date, :end_date,
          :delivery_start_date, :delivery_end_date,
          :customer_name, :customer_email, :customer_phone,
          :client_id, :manager_id, :venue_location_id,
          :status, :notes, :invoice_notes, :default_discount,
          booking_line_items_attributes: [:id, :bookable_type, :bookable_id, :quantity, :price_cents, :price_currency, :days, :_destroy]
        )
      end

      def booking_json(booking)
        {
          id: booking.id,
          reference_number: booking.reference_number,
          start_date: booking.start_date,
          end_date: booking.end_date,
          delivery_start_date: booking.delivery_start_date,
          delivery_end_date: booking.delivery_end_date,
          rental_days: booking.rental_days,
          customer: {
            name: booking.customer_name,
            email: booking.customer_email,
            phone: booking.customer_phone
          },
          client: booking.client ? {
            id: booking.client_id,
            name: booking.client.name,
            email: booking.client.email
          } : nil,
          manager: booking.manager ? {
            id: booking.manager_id,
            name: booking.manager.name,
            email: booking.manager.email
          } : nil,
          venue: booking.venue_location ? {
            id: booking.venue_location_id,
            name: booking.venue_location.name,
            address: booking.venue_location.address
          } : nil,
          status: booking.status,
          archived: booking.archived,
          total_price: {
            amount: booking.total_price_cents,
            currency: booking.total_price_currency,
            formatted: booking.total_price.format
          },
          total_paid: booking.total_payments_received,
          balance_due: booking.balance_due,
          fully_paid: booking.fully_paid?,
          default_discount: booking.default_discount,
          items_count: booking.booking_line_items.count,
          payments_count: booking.payments.active.count,
          created_at: booking.created_at,
          updated_at: booking.updated_at
        }
      end

      def booking_detail_json(booking)
        booking_json(booking).merge({
          notes: booking.notes,
          invoice_notes: booking.invoice_notes,
          line_items: booking.booking_line_items.active.map do |item|
            {
              id: item.id,
              bookable_type: item.bookable_type,
              bookable_id: item.bookable_id,
              bookable_name: item.bookable.name,
              quantity: item.quantity,
              days: item.days,
              workflow_status: item.workflow_status,
              discount_percent: item.discount_percent,
              comment: item.comment,
              price_per_day: {
                amount: item.price_cents,
                currency: item.price_currency,
                formatted: item.price.format
              },
              line_subtotal: {
                amount: item.line_subtotal.cents,
                currency: item.line_subtotal.currency.to_s,
                formatted: item.line_subtotal.format
              },
              line_total: {
                amount: item.line_total.cents,
                currency: item.line_total.currency.to_s,
                formatted: item.line_total.format
              }
            }
          end,
          payments: booking.payments.active.order(payment_date: :desc).map do |payment|
            {
              id: payment.id,
              payment_type: payment.payment_type,
              amount: {
                amount: payment.amount_cents,
                currency: payment.amount_currency,
                formatted: payment.amount.format
              },
              payment_date: payment.payment_date,
              payment_method: payment.payment_method,
              reference: payment.reference
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
