class AddLateReturnFieldsToBookingLineItems < ActiveRecord::Migration[8.1]
  def change
    add_column :booking_line_items, :actual_return_date, :datetime
    add_column :booking_line_items, :expected_return_date, :datetime
    add_column :booking_line_items, :late_fee_cents, :integer, default: 0
    add_column :booking_line_items, :late_fee_currency, :string, default: 'USD'
    add_column :booking_line_items, :days_overdue, :integer, default: 0
    add_column :booking_line_items, :overdue_notified_at, :datetime
    add_column :booking_line_items, :late_fee_calculated_at, :datetime

    # Add indexes for querying overdue items
    add_index :booking_line_items, :actual_return_date
    add_index :booking_line_items, :expected_return_date
    add_index :booking_line_items, :days_overdue
    add_index :booking_line_items, [:expected_return_date, :actual_return_date], name: 'index_line_items_on_return_dates'
  end
end
