class CreateProductBundleItems < ActiveRecord::Migration[8.1]
  def change
    create_table :product_bundle_items do |t|
      t.references :product_bundle, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, default: 1
      t.boolean :required, default: true
      t.integer :position, default: 0

      t.timestamps
    end

    add_index :product_bundle_items, [:product_bundle_id, :product_id], unique: true
    add_index :product_bundle_items, :position
  end
end
