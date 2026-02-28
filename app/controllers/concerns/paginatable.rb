# app/controllers/concerns/paginatable.rb
# Provides common pagination helper methods for API controllers
module Paginatable
  extend ActiveSupport::Concern

  # Generate pagination metadata for Kaminari-paginated collections
  # Returns hash with current_page, next_page, prev_page, total_pages, total_count
  def pagination_meta(collection)
    {
      current_page: collection.current_page,
      next_page: collection.next_page,
      prev_page: collection.prev_page,
      total_pages: collection.total_pages,
      total_count: collection.total_count,
      per_page: collection.limit_value
    }
  end

  # Parse pagination parameters from request params
  # Returns hash with page and per_page values
  def pagination_params
    {
      page: params[:page] || 1,
      per_page: [params[:per_page]&.to_i || 25, 100].min # Max 100 per page
    }
  end

  # Apply pagination to a collection using parsed params
  def paginate_collection(collection)
    pag_params = pagination_params
    collection.page(pag_params[:page]).per(pag_params[:per_page])
  end
end
