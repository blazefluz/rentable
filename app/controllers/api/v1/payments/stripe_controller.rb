# app/controllers/api/v1/payments/stripe_controller.rb
module Api
  module V1
    module Payments
      class StripeController < ApplicationController
        skip_before_action :verify_authenticity_token, only: [:webhook]

        before_action :set_stripe_key

        # POST /api/v1/payments/stripe/create_intent
        # Create a payment intent for a booking (full payment or deposit)
        def create_intent
          booking = Booking.find(params[:booking_id])

          # Calculate amount (full payment or partial deposit)
          amount_cents = if params[:amount_cents].present?
            params[:amount_cents].to_i
          elsif params[:deposit_percent].present?
            (booking.total_price_cents * params[:deposit_percent].to_f / 100).to_i
          else
            booking.balance_due # Pay remaining balance
          end

          # Create or retrieve Stripe customer
          customer = find_or_create_stripe_customer(booking)

          # Create Payment Intent
          intent = Stripe::PaymentIntent.create(
            amount: amount_cents,
            currency: booking.total_price_currency.downcase,
            customer: customer.id,
            metadata: {
              booking_id: booking.id,
              booking_reference: booking.reference_number,
              customer_name: booking.customer_name,
              customer_email: booking.customer_email
            },
            receipt_email: booking.customer_email,
            description: "Booking #{booking.reference_number}",
            automatic_payment_methods: {
              enabled: true,
              allow_redirects: 'never' # API-only, no redirects
            }
          )

          render json: {
            client_secret: intent.client_secret,
            payment_intent_id: intent.id,
            amount: intent.amount,
            currency: intent.currency,
            status: intent.status,
            customer_id: customer.id,
            booking: {
              id: booking.id,
              reference: booking.reference_number,
              total: booking.total_price_cents,
              balance_due: booking.balance_due
            }
          }
        rescue Stripe::StripeError => e
          render json: { error: e.message }, status: :unprocessable_entity
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Booking not found" }, status: :not_found
        end

        # POST /api/v1/payments/stripe/confirm_payment
        # Confirm a payment intent (for manual confirmation if needed)
        def confirm_payment
          intent = Stripe::PaymentIntent.retrieve(params[:payment_intent_id])

          if intent.status == 'requires_confirmation'
            intent.confirm
          end

          render json: {
            payment_intent_id: intent.id,
            status: intent.status,
            amount: intent.amount,
            currency: intent.currency
          }
        rescue Stripe::StripeError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        # GET /api/v1/payments/stripe/payment_status/:payment_intent_id
        # Check status of a payment
        def payment_status
          intent = Stripe::PaymentIntent.retrieve(params[:payment_intent_id])

          render json: {
            payment_intent_id: intent.id,
            status: intent.status,
            amount: intent.amount,
            currency: intent.currency,
            created: Time.at(intent.created),
            metadata: intent.metadata
          }
        rescue Stripe::StripeError => e
          render json: { error: e.message }, status: :not_found
        end

        # POST /api/v1/payments/stripe/refund
        # Refund a payment
        def refund
          payment_intent_id = params[:payment_intent_id]
          amount_cents = params[:amount_cents]&.to_i
          reason = params[:reason] || 'requested_by_customer'

          intent = Stripe::PaymentIntent.retrieve(payment_intent_id)
          charge_id = intent.charges.data.first&.id

          return render json: { error: "No charge found for this payment" }, status: :bad_request unless charge_id

          refund_params = {
            charge: charge_id,
            reason: reason
          }
          refund_params[:amount] = amount_cents if amount_cents

          refund = Stripe::Refund.create(refund_params)

          # Record refund in database
          booking = Booking.find_by(id: intent.metadata.booking_id)
          if booking
            booking.payments.create!(
              payment_type: :payment_received,
              amount_cents: -refund.amount,
              amount_currency: refund.currency.upcase,
              payment_method: 'Stripe Refund',
              reference: refund.id,
              comment: "Refund: #{reason}",
              payment_date: Time.current
            )
          end

          render json: {
            refund_id: refund.id,
            amount: refund.amount,
            currency: refund.currency,
            status: refund.status,
            reason: refund.reason
          }
        rescue Stripe::StripeError => e
          render json: { error: e.message }, status: :unprocessable_entity
        end

        # POST /api/v1/payments/stripe/webhook
        # Stripe webhook endpoint for payment events
        def webhook
          payload = request.body.read
          sig_header = request.env['HTTP_STRIPE_SIGNATURE']
          endpoint_secret = ENV['STRIPE_WEBHOOK_SECRET']

          begin
            event = Stripe::Webhook.construct_event(payload, sig_header, endpoint_secret)
          rescue JSON::ParserError => e
            return render json: { error: 'Invalid payload' }, status: :bad_request
          rescue Stripe::SignatureVerificationError => e
            return render json: { error: 'Invalid signature' }, status: :bad_request
          end

          # Handle the event
          case event.type
          when 'payment_intent.succeeded'
            handle_payment_succeeded(event.data.object)
          when 'payment_intent.payment_failed'
            handle_payment_failed(event.data.object)
          when 'payment_intent.canceled'
            handle_payment_canceled(event.data.object)
          when 'charge.refunded'
            handle_refund(event.data.object)
          when 'charge.dispute.created'
            handle_dispute_created(event.data.object)
          when 'charge.dispute.closed'
            handle_dispute_closed(event.data.object)
          else
            Rails.logger.info "Unhandled Stripe event type: #{event.type}"
          end

          render json: { received: true }, status: :ok
        end

        private

        def set_stripe_key
          Stripe.api_key = ENV['STRIPE_SECRET_KEY']
        end

        def find_or_create_stripe_customer(booking)
          # Check if customer already exists in Stripe
          if booking.client&.email.present?
            customers = Stripe::Customer.list(email: booking.client.email, limit: 1)
            return customers.data.first if customers.data.any?
          end

          # Create new customer
          Stripe::Customer.create(
            email: booking.customer_email,
            name: booking.customer_name,
            phone: booking.customer_phone,
            metadata: {
              booking_id: booking.id,
              client_id: booking.client_id
            }
          )
        end

        def handle_payment_succeeded(payment_intent)
          booking_id = payment_intent.metadata.booking_id
          booking = Booking.find_by(id: booking_id)

          return unless booking

          # Create payment record
          payment = booking.payments.create!(
            payment_type: :payment_received,
            amount_cents: payment_intent.amount,
            amount_currency: payment_intent.currency.upcase,
            payment_method: 'Stripe',
            reference: payment_intent.id,
            payment_date: Time.current,
            comment: "Stripe payment succeeded"
          )

          # Update booking status if fully paid
          if booking.fully_paid?
            booking.update(status: :confirmed)
          end

          # Send payment confirmation email
          SendPaymentConfirmationJob.perform_later(payment.id)

          Rails.logger.info "Payment succeeded for booking #{booking.reference_number}: #{payment_intent.id}"
        rescue => e
          Rails.logger.error "Failed to handle payment success: #{e.message}"
        end

        def handle_payment_failed(payment_intent)
          booking_id = payment_intent.metadata.booking_id
          booking = Booking.find_by(id: booking_id)

          return unless booking

          booking.update(
            notes: [
              booking.notes,
              "Payment failed: #{Time.current}",
              "Reason: #{payment_intent.last_payment_error&.message || 'Unknown'}",
              "Stripe Payment ID: #{payment_intent.id}"
            ].compact.join("\n")
          )

          Rails.logger.warn "Payment failed for booking #{booking.reference_number}: #{payment_intent.id}"
          # TODO: Send payment failed email notification
        rescue => e
          Rails.logger.error "Failed to handle payment failure: #{e.message}"
        end

        def handle_payment_canceled(payment_intent)
          booking_id = payment_intent.metadata.booking_id
          booking = Booking.find_by(id: booking_id)

          return unless booking

          booking.update(
            notes: [
              booking.notes,
              "Payment canceled: #{Time.current}",
              "Stripe Payment ID: #{payment_intent.id}"
            ].compact.join("\n")
          )

          Rails.logger.info "Payment canceled for booking #{booking.reference_number}: #{payment_intent.id}"
        rescue => e
          Rails.logger.error "Failed to handle payment cancellation: #{e.message}"
        end

        def handle_refund(charge)
          # Refund is already created in the refund endpoint
          # This webhook confirms it was processed
          Rails.logger.info "Refund processed: #{charge.id}"
        end

        def handle_dispute_created(charge)
          # Find related booking
          payment = Payment.find_by(reference: charge.payment_intent)
          return unless payment

          booking = payment.booking
          booking.update(
            notes: [
              booking.notes,
              "⚠️ DISPUTE CREATED: #{Time.current}",
              "Charge ID: #{charge.id}",
              "Amount: #{Money.new(charge.amount, charge.currency.upcase).format}",
              "Reason: #{charge.dispute&.reason}"
            ].compact.join("\n")
          )

          Rails.logger.warn "Dispute created for booking #{booking.reference_number}"
        end

        def handle_dispute_closed(charge)
          payment = Payment.find_by(reference: charge.payment_intent)
          return unless payment

          booking = payment.booking
          status = charge.dispute&.status
          outcome = status == 'won' ? 'WON ✅' : status == 'lost' ? 'LOST ❌' : 'CLOSED'

          booking.update(
            notes: [
              booking.notes,
              "Dispute #{outcome}: #{Time.current}",
              "Charge ID: #{charge.id}"
            ].compact.join("\n")
          )

          Rails.logger.info "Dispute #{outcome} for booking #{booking.reference_number}"
        end
      end
    end
  end
end
