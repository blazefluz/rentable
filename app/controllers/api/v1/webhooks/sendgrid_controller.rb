# frozen_string_literal: true

module Api
  module V1
    module Webhooks
      class SendgridController < ApplicationController
        skip_before_action :authenticate_user!, only: [:event]
        skip_before_action :verify_authenticity_token, only: [:event]

        # POST /api/v1/webhooks/sendgrid/event
        def event
          # SendGrid sends events as an array
          events = params[:_json] || [params]

          events.each do |event_data|
            process_event(event_data)
          end

          render json: { message: 'Webhook received' }, status: :ok
        rescue StandardError => e
          Rails.logger.error "SendGrid webhook error: #{e.message}"
          Rails.logger.error e.backtrace.join("\n")

          render json: { error: 'Webhook processing failed' }, status: :internal_server_error
        end

        private

        def process_event(event_data)
          # Verify the webhook (optional but recommended)
          # unless verify_webhook_signature
          #   Rails.logger.warn "Invalid SendGrid webhook signature"
          #   return
          # end

          # Queue the webhook for processing
          ProcessEmailWebhookJob.perform_later(event_data.to_h)
        end

        def verify_webhook_signature
          # SendGrid webhook signature verification
          # This requires the webhook public key from SendGrid
          # signature = request.headers['X-Twilio-Email-Event-Webhook-Signature']
          # timestamp = request.headers['X-Twilio-Email-Event-Webhook-Timestamp']
          #
          # return false if signature.blank? || timestamp.blank?
          #
          # public_key = ENV['SENDGRID_WEBHOOK_PUBLIC_KEY']
          # return false if public_key.blank?
          #
          # # Verify the signature
          # # Implementation depends on SendGrid's verification method
          # true

          true # For now, accept all webhooks
        end
      end
    end
  end
end
