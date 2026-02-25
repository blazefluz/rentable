class EnhanceBookings < ActiveRecord::Migration[8.1]
  def change
    # Add project manager (user who manages the booking)
    add_reference :bookings, :manager, null: true, foreign_key: { to_table: :users }, index: true

    # Add delivery dates (separate from usage dates)
    add_column :bookings, :delivery_start_date, :datetime
    add_column :bookings, :delivery_end_date, :datetime
    add_index :bookings, [:delivery_start_date, :delivery_end_date]

    # Add invoice notes
    add_column :bookings, :invoice_notes, :text

    # Add default discount (percentage)
    add_column :bookings, :default_discount, :decimal, precision: 5, scale: 2, default: 0.0

    # Add archived and deleted flags
    add_column :bookings, :archived, :boolean, default: false, null: false
    add_column :bookings, :deleted, :boolean, default: false, null: false
    add_index :bookings, :archived
    add_index :bookings, :deleted
  end
end
