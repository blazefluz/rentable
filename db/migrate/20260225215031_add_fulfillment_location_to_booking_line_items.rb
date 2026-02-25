class AddFulfillmentLocationToBookingLineItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :booking_line_items, :fulfillment_location, null: true, foreign_key: { to_table: :locations }
    add_reference :booking_line_items, :pickup_location, null: true, foreign_key: { to_table: :locations }
    add_reference :booking_line_items, :delivery_location, null: true, foreign_key: { to_table: :locations }

    add_column :booking_line_items, :requires_transfer, :boolean, default: false
    add_column :booking_line_items, :transfer_status, :integer, default: 0
    add_column :booking_line_items, :picked_at, :datetime
    add_column :booking_line_items, :delivered_at, :datetime
    add_column :booking_line_items, :ready_for_pickup_at, :datetime

    # Indexes are automatically created by add_reference, only add status indexes
    add_index :booking_line_items, :transfer_status
    add_index :booking_line_items, :requires_transfer
  end
end
