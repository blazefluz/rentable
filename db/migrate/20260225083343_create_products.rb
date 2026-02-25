class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.text :description
      t.integer :daily_price_cents, null: false, default: 0
      t.string :daily_price_currency, null: false, default: "NGN"
      t.integer :quantity, null: false, default: 1
      t.string :category
      t.string :barcode
      t.string :serial_numbers, array: true, default: []
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :products, :barcode, unique: true, where: "barcode IS NOT NULL"
    add_index :products, :category
    add_index :products, :active
  end
end
