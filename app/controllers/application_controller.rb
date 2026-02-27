class ApplicationController < ActionController::API
  # Include authentication concern
  include Authenticatable

  # Include multi-tenancy concern
  include SetCurrentTenant

  # REQUIRE authentication by default (controllers can skip if needed)
  # All API endpoints are now protected unless explicitly made public
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActsAsTenant::Errors::NoTenantSet, with: :tenant_not_set

  private

  def record_not_found(exception)
    render json: {
      error: "#{exception.model} not found"
    }, status: :not_found
  end

  def tenant_not_set
    render json: {
      error: 'Company context not set. Please ensure you are accessing the correct subdomain.'
    }, status: :bad_request
  end
end
