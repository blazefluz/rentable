class EnhanceBookingLineItems < ActiveRecord::Migration[8.1]
  def change
    # Add workflow status (0-110 scale from AdamRMS)
    add_column :booking_line_items, :workflow_status, :integer, default: 0, null: false
    add_index :booking_line_items, :workflow_status

    # Add discount percentage
    add_column :booking_line_items, :discount_percent, :decimal, precision: 5, scale: 2, default: 0.0

    # Add comment/notes for this line item
    add_column :booking_line_items, :comment, :text

    # Add deleted flag (soft delete)
    add_column :booking_line_items, :deleted, :boolean, default: false, null: false
    add_index :booking_line_items, :deleted
  end
end
