# app/controllers/concerns/error_handleable.rb
# Provides common error handling for API controllers
module ErrorHandleable
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound, with: :handle_record_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
    rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing
    rescue_from ActsAsTenant::Errors::NoTenantSet, with: :handle_tenant_not_set
    rescue_from ArgumentError, with: :handle_argument_error
  end

  private

  def handle_record_not_found(exception)
    render json: {
      error: "#{exception.model} not found"
    }, status: :not_found
  end

  def handle_record_invalid(exception)
    render json: {
      errors: exception.record.errors.full_messages
    }, status: :unprocessable_entity
  end

  def handle_parameter_missing(exception)
    render json: {
      error: "Missing required parameter: #{exception.param}"
    }, status: :bad_request
  end

  def handle_tenant_not_set
    render json: {
      error: 'Company context not set. Please ensure you are accessing the correct subdomain.'
    }, status: :bad_request
  end

  def handle_argument_error(exception)
    render json: {
      error: exception.message
    }, status: :bad_request
  end

  # Handle JSON parse errors
  def handle_json_parse_error(exception)
    render json: {
      error: "Invalid JSON format: #{exception.message}"
    }, status: :bad_request
  end

  # Handle date parse errors
  def handle_date_error(exception)
    render json: {
      error: "Invalid date format: #{exception.message}"
    }, status: :bad_request
  end
end
