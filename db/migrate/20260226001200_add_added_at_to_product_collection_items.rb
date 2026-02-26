class AddAddedAtToProductCollectionItems < ActiveRecord::Migration[8.1]
  def change
    add_column :product_collection_items, :added_at, :datetime
    add_column :product_collection_items, :added_by_id, :bigint

    add_index :product_collection_items, :added_by_id
    add_foreign_key :product_collection_items, :users, column: :added_by_id
  end
end
