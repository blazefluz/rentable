# frozen_string_literal: true

module Api
  module V1
    class EmailTemplatesController < ApplicationController
      before_action :set_email_template, only: [:show, :update, :destroy, :preview]

      # GET /api/v1/email_templates
      def index
        @email_templates = EmailTemplate.all.order(created_at: :desc)

        # Filter by category if provided
        @email_templates = @email_templates.where(category: params[:category]) if params[:category].present?

        # Filter by active status if provided
        @email_templates = @email_templates.where(active: params[:active]) if params[:active].present?

        render json: {
          email_templates: @email_templates.map { |template| template_json(template) }
        }
      end

      # GET /api/v1/email_templates/:id
      def show
        render json: {
          email_template: template_json(@email_template, detailed: true)
        }
      end

      # POST /api/v1/email_templates
      def create
        @email_template = EmailTemplate.new(email_template_params)
        @email_template.company = current_company

        if @email_template.save
          render json: {
            email_template: template_json(@email_template, detailed: true),
            message: 'Email template created successfully'
          }, status: :created
        else
          render json: {
            errors: @email_template.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/email_templates/:id
      def update
        if @email_template.update(email_template_params)
          render json: {
            email_template: template_json(@email_template, detailed: true),
            message: 'Email template updated successfully'
          }
        else
          render json: {
            errors: @email_template.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/email_templates/:id
      def destroy
        @email_template.destroy
        render json: {
          message: 'Email template deleted successfully'
        }
      end

      # POST /api/v1/email_templates/:id/preview
      def preview
        sample_variables = params[:variables] || {}

        preview_data = @email_template.preview(sample_variables)

        render json: {
          preview: {
            subject: preview_data[:subject],
            html_body: preview_data[:html_body],
            text_body: preview_data[:text_body],
            variables_used: preview_data[:variables_used],
            sample_variables: sample_variables
          }
        }
      end

      private

      def set_email_template
        @email_template = EmailTemplate.find(params[:id])
      end

      def email_template_params
        params.require(:email_template).permit(
          :name,
          :category,
          :subject,
          :html_body,
          :text_body,
          :active,
          variable_schema: {}
        )
      end

      def template_json(template, detailed: false)
        data = {
          id: template.id,
          name: template.name,
          category: template.category,
          subject: template.subject,
          active: template.active,
          created_at: template.created_at,
          updated_at: template.updated_at
        }

        if detailed
          data.merge!({
            html_body: template.html_body,
            text_body: template.text_body,
            variable_schema: template.variable_schema,
            available_variables: template.available_variables,
            variables_in_templates: template.extract_variables_from_templates
          })
        end

        data
      end
    end
  end
end
