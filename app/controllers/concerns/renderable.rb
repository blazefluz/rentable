# app/controllers/concerns/renderable.rb
# Provides common JSON rendering helper methods for API controllers
module Renderable
  extend ActiveSupport::Concern

  # Render success response with data
  def render_success(data, message: nil, status: :ok)
    response = data
    response[:message] = message if message.present?
    render json: response, status: status
  end

  # Render created resource response
  def render_created(resource_name, resource_data, message: nil)
    render json: {
      resource_name.to_sym => resource_data,
      message: message || "#{resource_name.humanize} created successfully"
    }, status: :created
  end

  # Render error response with messages
  def render_errors(errors, status: :unprocessable_entity)
    render json: {
      errors: errors.is_a?(Array) ? errors : [errors]
    }, status: status
  end

  # Render validation errors from ActiveRecord model
  def render_validation_errors(model)
    render json: {
      errors: model.errors.full_messages
    }, status: :unprocessable_entity
  end

  # Render not found error
  def render_not_found(message = "Resource not found")
    render json: {
      error: message
    }, status: :not_found
  end

  # Render forbidden error
  def render_forbidden(message = "Forbidden")
    render json: {
      error: message
    }, status: :forbidden
  end

  # Render bad request error
  def render_bad_request(message = "Bad request")
    render json: {
      error: message
    }, status: :bad_request
  end

  # Render unauthorized error
  def render_unauthorized(message = "Unauthorized. Please provide a valid authentication token.")
    render json: {
      error: message
    }, status: :unauthorized
  end
end
