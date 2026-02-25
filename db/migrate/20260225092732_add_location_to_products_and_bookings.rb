class AddLocationToProductsAndBookings < ActiveRecord::Migration[8.1]
  def change
    # Add storage location to products
    add_reference :products, :storage_location, null: true, foreign_key: { to_table: :locations }, index: true

    # Add venue location to bookings
    add_reference :bookings, :venue_location, null: true, foreign_key: { to_table: :locations }, index: true
  end
end
