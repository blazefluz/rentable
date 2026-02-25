class CreateProductAccessories < ActiveRecord::Migration[8.1]
  def change
    create_table :product_accessories do |t|
      t.references :product, null: false, foreign_key: true
      t.references :accessory, null: false, foreign_key: { to_table: :products }
      t.integer :accessory_type, default: 0
      t.boolean :required, default: false
      t.integer :default_quantity, default: 1

      t.timestamps
    end

    add_index :product_accessories, [:product_id, :accessory_id], unique: true
  end
end
