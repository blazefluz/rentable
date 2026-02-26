class CreateProductCollectionItems < ActiveRecord::Migration[8.1]
  def change
    create_table :product_collection_items do |t|
      t.references :product_collection, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :position
      t.boolean :featured
      t.text :notes

      t.timestamps
    end
  end
end
