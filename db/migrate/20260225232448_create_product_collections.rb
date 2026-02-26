class CreateProductCollections < ActiveRecord::Migration[8.1]
  def change
    create_table :product_collections do |t|
      t.string :name
      t.string :slug
      t.text :description
      t.string :short_description
      t.bigint :parent_collection_id
      t.integer :collection_type
      t.integer :visibility
      t.integer :position
      t.boolean :active
      t.boolean :featured
      t.integer :product_count
      t.string :meta_title
      t.text :meta_description
      t.date :start_date
      t.date :end_date
      t.string :icon
      t.string :color
      t.string :display_template
      t.jsonb :rules
      t.boolean :is_dynamic

      t.timestamps
    end
    add_index :product_collections, :slug, unique: true
  end
end
