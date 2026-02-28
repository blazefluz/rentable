# frozen_string_literal: true

module Api
  module V1
    class EmailCampaignsController < ApplicationController
      before_action :set_email_campaign, only: [:show, :update, :destroy, :analytics, :send_campaign, :pause, :resume]

      # GET /api/v1/email_campaigns
      def index
        @email_campaigns = EmailCampaign.all
                                        .includes(:email_sequences)
                                        .order(created_at: :desc)

        # Filter by status if provided
        @email_campaigns = @email_campaigns.where(status: params[:status]) if params[:status].present?

        # Filter by campaign type if provided
        @email_campaigns = @email_campaigns.where(campaign_type: params[:campaign_type]) if params[:campaign_type].present?

        render json: {
          email_campaigns: @email_campaigns.map { |campaign| campaign_json(campaign) }
        }
      end

      # GET /api/v1/email_campaigns/:id
      def show
        render json: {
          email_campaign: campaign_json(@email_campaign, detailed: true)
        }
      end

      # POST /api/v1/email_campaigns
      def create
        @email_campaign = EmailCampaign.new(email_campaign_params)
        @email_campaign.company = current_company

        if @email_campaign.save
          render json: {
            email_campaign: campaign_json(@email_campaign, detailed: true),
            message: 'Email campaign created successfully'
          }, status: :created
        else
          render json: {
            errors: @email_campaign.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/email_campaigns/:id
      def update
        if @email_campaign.update(email_campaign_params)
          render json: {
            email_campaign: campaign_json(@email_campaign, detailed: true),
            message: 'Email campaign updated successfully'
          }
        else
          render json: {
            errors: @email_campaign.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/email_campaigns/:id
      def destroy
        @email_campaign.destroy
        render json: {
          message: 'Email campaign deleted successfully'
        }
      end

      # GET /api/v1/email_campaigns/:id/analytics
      def analytics
        metrics = @email_campaign.metrics

        render json: {
          campaign: {
            id: @email_campaign.id,
            name: @email_campaign.name,
            campaign_type: @email_campaign.campaign_type,
            status: @email_campaign.status
          },
          metrics: {
            total_sent: metrics[:total_sent],
            delivered: metrics[:delivered],
            opened: metrics[:opened],
            clicked: metrics[:clicked],
            bounced: metrics[:bounced],
            unsubscribed: metrics[:unsubscribed],
            open_rate: @email_campaign.open_rate,
            click_rate: @email_campaign.click_rate,
            conversion_rate: @email_campaign.conversion_rate,
            revenue_attributed: @email_campaign.revenue_attributed.format
          },
          sequences: @email_campaign.email_sequences.map { |seq| sequence_analytics(seq) }
        }
      end

      # POST /api/v1/email_campaigns/:id/send
      def send_campaign
        unless @email_campaign.can_send?
          return render json: {
            error: 'Campaign cannot be sent at this time'
          }, status: :unprocessable_entity
        end

        client_segment_id = params[:client_segment_id]

        # Queue the campaign for sending
        SendEmailCampaignJob.perform_later(@email_campaign.id, client_segment_id)

        render json: {
          message: 'Email campaign queued for sending',
          campaign: campaign_json(@email_campaign)
        }
      end

      # POST /api/v1/email_campaigns/:id/pause
      def pause
        @email_campaign.pause!
        render json: {
          message: 'Campaign paused successfully',
          campaign: campaign_json(@email_campaign)
        }
      end

      # POST /api/v1/email_campaigns/:id/resume
      def resume
        @email_campaign.resume!
        render json: {
          message: 'Campaign resumed successfully',
          campaign: campaign_json(@email_campaign)
        }
      end

      private

      def set_email_campaign
        @email_campaign = EmailCampaign.find(params[:id])
      end

      def email_campaign_params
        params.require(:email_campaign).permit(
          :name,
          :campaign_type,
          :status,
          :delay_hours,
          :active,
          :starts_at,
          :ends_at,
          trigger_conditions: {}
        )
      end

      def campaign_json(campaign, detailed: false)
        data = {
          id: campaign.id,
          name: campaign.name,
          campaign_type: campaign.campaign_type,
          status: campaign.status,
          active: campaign.active,
          delay_hours: campaign.delay_hours,
          starts_at: campaign.starts_at,
          ends_at: campaign.ends_at,
          trigger_conditions: campaign.trigger_conditions,
          created_at: campaign.created_at,
          updated_at: campaign.updated_at
        }

        if detailed
          data.merge!({
            sequences_count: campaign.email_sequences.count,
            sequences: campaign.email_sequences.ordered.map { |seq| sequence_json(seq) },
            metrics: {
              total_sent: campaign.metrics[:total_sent],
              open_rate: campaign.open_rate,
              click_rate: campaign.click_rate
            }
          })
        end

        data
      end

      def sequence_json(sequence)
        {
          id: sequence.id,
          sequence_number: sequence.sequence_number,
          subject_template: sequence.subject_template,
          body_template: sequence.body_template,
          send_delay_hours: sequence.send_delay_hours,
          active: sequence.active
        }
      end

      def sequence_analytics(sequence)
        metrics = sequence.metrics

        {
          sequence_number: sequence.sequence_number,
          subject: sequence.subject_template,
          total_sent: metrics[:total_sent],
          delivered: metrics[:delivered],
          opened: metrics[:opened],
          clicked: metrics[:clicked],
          bounced: metrics[:bounced],
          open_rate: sequence.open_rate
        }
      end
    end
  end
end
