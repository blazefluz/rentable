# app/controllers/concerns/authenticatable.rb
module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    attr_reader :current_user
  end

  private

  def authenticate_user!
    token = extract_token_from_header
    return render_unauthorized unless token

    @current_user = User.from_jwt(token)
    render_unauthorized unless @current_user
  end

  def extract_token_from_header
    auth_header = request.headers['Authorization']
    return nil unless auth_header

    # Support both "Bearer TOKEN" and "TOKEN" formats
    auth_header.sub(/^Bearer\s/, '')
  end

  def render_unauthorized
    render json: {
      error: "Unauthorized. Please provide a valid authentication token."
    }, status: :unauthorized
  end

  def require_admin!
    unless current_user&.role_admin?
      render json: {
        error: "Forbidden. Admin access required."
      }, status: :forbidden
    end
  end

  def require_staff_or_admin!
    unless current_user&.role_staff? || current_user&.role_admin?
      render json: {
        error: "Forbidden. Staff or admin access required."
      }, status: :forbidden
    end
  end
end
