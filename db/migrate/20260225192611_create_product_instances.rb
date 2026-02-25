class CreateProductInstances < ActiveRecord::Migration[8.1]
  def change
    create_table :product_instances do |t|
      t.references :product, null: false, foreign_key: true
      t.string :serial_number
      t.string :asset_tag
      t.integer :condition, default: 0
      t.integer :status, default: 0
      t.date :purchase_date
      t.integer :purchase_price_cents
      t.string :purchase_price_currency
      t.references :current_location, foreign_key: { to_table: :locations }
      t.text :notes
      t.boolean :deleted, default: false

      t.timestamps
    end

    add_index :product_instances, :serial_number, unique: true
    add_index :product_instances, :asset_tag, unique: true
  end
end
