class CreateProductBundles < ActiveRecord::Migration[8.1]
  def change
    create_table :product_bundles do |t|
      t.string :name
      t.text :description
      t.integer :bundle_type, default: 0
      t.boolean :enforce_bundling, default: false
      t.decimal :discount_percentage, precision: 5, scale: 2
      t.boolean :active, default: true
      t.boolean :deleted, default: false
      t.references :instance, foreign_key: true

      t.timestamps
    end

    add_index :product_bundles, :bundle_type
    add_index :product_bundles, :active
  end
end
