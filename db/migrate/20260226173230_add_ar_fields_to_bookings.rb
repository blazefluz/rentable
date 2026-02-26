class AddArFieldsToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :payment_due_date, :date
    add_column :bookings, :days_past_due, :integer, default: 0
    add_column :bookings, :aging_bucket, :integer, default: 0
    add_column :bookings, :collection_status, :integer, default: 0
    add_column :bookings, :last_payment_reminder_sent_at, :datetime
    add_column :bookings, :payment_reminder_count, :integer, default: 0
    add_column :bookings, :collection_assigned_to_id, :bigint
    add_column :bookings, :collection_notes, :text

    # Indexes for AR queries
    add_index :bookings, :payment_due_date
    add_index :bookings, :days_past_due
    add_index :bookings, :aging_bucket
    add_index :bookings, :collection_status
    add_index :bookings, :collection_assigned_to_id
  end
end
