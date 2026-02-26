class CreateCollectionViews < ActiveRecord::Migration[8.1]
  def change
    create_table :collection_views do |t|
      t.references :product_collection, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.datetime :viewed_at
      t.string :ip_address
      t.string :user_agent
      t.string :referrer
      t.string :session_id

      t.timestamps
    end

    add_index :collection_views, :session_id
    add_index :collection_views, :viewed_at
    add_index :collection_views, [:product_collection_id, :viewed_at]
  end
end
