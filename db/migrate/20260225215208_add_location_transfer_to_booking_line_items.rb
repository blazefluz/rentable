class AddLocationTransferToBookingLineItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :booking_line_items, :location_transfer, null: true, foreign_key: true
  end
end
