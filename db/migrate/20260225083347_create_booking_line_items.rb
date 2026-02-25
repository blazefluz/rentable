class CreateBookingLineItems < ActiveRecord::Migration[8.1]
  def change
    create_table :booking_line_items do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :bookable, polymorphic: true, null: false
      t.integer :quantity, null: false, default: 1
      t.integer :price_cents, null: false, default: 0
      t.string :price_currency, null: false, default: "NGN"
      t.integer :days, null: false, default: 1

      t.timestamps
    end

    add_index :booking_line_items, [:bookable_type, :bookable_id]
  end
end
