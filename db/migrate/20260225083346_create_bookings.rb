class CreateBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :bookings do |t|
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.string :customer_name, null: false
      t.string :customer_email, null: false
      t.string :customer_phone
      t.integer :status, null: false, default: 0
      t.integer :total_price_cents, null: false, default: 0
      t.string :total_price_currency, null: false, default: "NGN"
      t.text :notes
      t.string :reference_number

      t.timestamps
    end

    add_index :bookings, :status
    add_index :bookings, :customer_email
    add_index :bookings, :reference_number, unique: true
    add_index :bookings, [:start_date, :end_date]
  end
end
