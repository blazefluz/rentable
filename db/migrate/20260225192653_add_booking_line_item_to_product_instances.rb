class AddBookingLineItemToProductInstances < ActiveRecord::Migration[8.1]
  def change
    add_reference :product_instances, :booking_line_item, null: false, foreign_key: true
  end
end
