class CreateProductTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :product_types do |t|
      t.string :name, null: false
      t.text :description
      t.string :category
      t.references :manufacturer, null: true, foreign_key: true
      t.integer :daily_price_cents, default: 0, null: false
      t.string :daily_price_currency, default: "USD", null: false
      t.integer :weekly_price_cents, default: 0, null: false
      t.string :weekly_price_currency, default: "USD", null: false
      t.integer :value_cents, default: 0, null: false
      t.decimal :mass, precision: 10, scale: 2
      t.string :product_link
      t.jsonb :custom_fields, default: {}

      t.timestamps
    end

    add_index :product_types, :name
    add_index :product_types, :category
    add_index :product_types, :custom_fields, using: :gin
  end
end
