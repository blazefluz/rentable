class ApplicationController < ActionController::API
  # Include common concerns
  include Authenticatable        # Authentication and authorization
  include SetCurrentTenant        # Multi-tenancy support
  include ErrorHandleable         # Common error handling
  include Paginatable            # Pagination helpers
  include Renderable             # JSON rendering helpers

  # REQUIRE authentication by default (controllers can skip if needed)
  # All API endpoints are now protected unless explicitly made public
  before_action :authenticate_user!
end
