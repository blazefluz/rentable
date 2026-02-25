class CreateKits < ActiveRecord::Migration[8.1]
  def change
    create_table :kits do |t|
      t.string :name, null: false
      t.text :description
      t.integer :daily_price_cents, null: false, default: 0
      t.string :daily_price_currency, null: false, default: "NGN"
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :kits, :active
  end
end
