class ApplicationController < ActionController::Base
  # Disable CSRF for API endpoints
  skip_before_action :verify_authenticity_token, if: -> { request.format.json? }

  # Include authentication concern
  include Authenticatable

  # REQUIRE authentication by default (controllers can skip if needed)
  # All API endpoints are now protected unless explicitly made public
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  private

  def record_not_found(exception)
    render json: {
      error: "#{exception.model} not found"
    }, status: :not_found
  end
end
