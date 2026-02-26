class RefreshDynamicCollectionsJob < ApplicationJob
  queue_as :default

  # Refresh all dynamic collections
  # Can be called with specific collection IDs: perform(collection_ids: [1, 2, 3])
  # Or with no args to refresh all dynamic collections: perform
  def perform(collection_ids: nil)
    collections = if collection_ids.present?
                    ProductCollection.where(id: collection_ids, is_dynamic: true)
                  else
                    ProductCollection.dynamic.active
                  end

    collections.find_each do |collection|
      begin
        collection.refresh_dynamic_products
        Rails.logger.info "Refreshed dynamic collection: #{collection.name} (ID: #{collection.id})"
      rescue => e
        Rails.logger.error "Failed to refresh collection #{collection.id}: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
      end
    end
  end
end
