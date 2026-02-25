class AddDeliveryTrackingToBookingLineItems < ActiveRecord::Migration[8.1]
  def change
    add_column :booking_line_items, :delivery_start_date, :datetime
    add_column :booking_line_items, :delivery_end_date, :datetime
    add_column :booking_line_items, :delivery_method, :integer, default: 0
    add_column :booking_line_items, :delivery_cost_cents, :integer, default: 0
    add_column :booking_line_items, :delivery_cost_currency, :string, default: 'USD'
    add_column :booking_line_items, :delivery_status, :integer, default: 0
    add_column :booking_line_items, :delivery_notes, :text
    add_column :booking_line_items, :delivery_tracking_number, :string
    add_column :booking_line_items, :delivery_carrier, :string
    add_column :booking_line_items, :signature_required, :boolean, default: false
    add_column :booking_line_items, :signature_captured_at, :datetime
    add_reference :booking_line_items, :delivered_by, null: true, foreign_key: { to_table: :users }

    add_index :booking_line_items, :delivery_method
    add_index :booking_line_items, :delivery_status
    add_index :booking_line_items, :delivery_start_date
    add_index :booking_line_items, :delivery_tracking_number
  end
end
