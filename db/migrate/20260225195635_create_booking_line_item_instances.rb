class CreateBookingLineItemInstances < ActiveRecord::Migration[8.1]
  def change
    create_table :booking_line_item_instances do |t|
      t.references :booking_line_item, null: false, foreign_key: true
      t.references :product_instance, null: false, foreign_key: true

      t.timestamps
    end

    add_index :booking_line_item_instances, [:booking_line_item_id, :product_instance_id],
              unique: true, name: 'index_booking_line_item_instances_unique'

    # Remove the old single reference from product_instances if it exists
    if column_exists?(:product_instances, :booking_line_item_id)
      remove_reference :product_instances, :booking_line_item, foreign_key: true
    end
  end
end
