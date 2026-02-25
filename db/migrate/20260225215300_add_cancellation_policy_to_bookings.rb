class AddCancellationPolicyToBookings < ActiveRecord::Migration[8.1]
  def up
    add_column :bookings, :cancellation_policy, :integer, default: 0, null: false
    add_column :bookings, :cancellation_deadline_hours, :integer, default: 168 # 7 days default
    add_column :bookings, :cancellation_fee_percentage, :decimal, precision: 5, scale: 2, default: 0.0
    add_column :bookings, :cancelled_at, :datetime
    add_column :bookings, :cancelled_by_id, :bigint
    add_column :bookings, :cancellation_reason, :text
    add_column :bookings, :refund_amount_cents, :integer, default: 0
    add_column :bookings, :refund_amount_currency, :string, default: "USD"
    add_column :bookings, :refund_status, :integer, default: 0
    add_column :bookings, :refund_processed_at, :datetime

    add_index :bookings, :cancellation_policy
    add_index :bookings, :cancelled_at
    add_index :bookings, :cancelled_by_id
    add_index :bookings, :refund_status

    add_foreign_key :bookings, :users, column: :cancelled_by_id, on_delete: :nullify if foreign_key_exists?(:bookings, :users, column: :cancelled_by_id) == false
  end

  def down
    remove_foreign_key :bookings, :users, column: :cancelled_by_id if foreign_key_exists?(:bookings, :users, column: :cancelled_by_id)

    remove_index :bookings, :refund_status if index_exists?(:bookings, :refund_status)
    remove_index :bookings, :cancelled_by_id if index_exists?(:bookings, :cancelled_by_id)
    remove_index :bookings, :cancelled_at if index_exists?(:bookings, :cancelled_at)
    remove_index :bookings, :cancellation_policy if index_exists?(:bookings, :cancellation_policy)

    remove_column :bookings, :refund_processed_at if column_exists?(:bookings, :refund_processed_at)
    remove_column :bookings, :refund_status if column_exists?(:bookings, :refund_status)
    remove_column :bookings, :refund_amount_currency if column_exists?(:bookings, :refund_amount_currency)
    remove_column :bookings, :refund_amount_cents if column_exists?(:bookings, :refund_amount_cents)
    remove_column :bookings, :cancellation_reason if column_exists?(:bookings, :cancellation_reason)
    remove_column :bookings, :cancelled_by_id if column_exists?(:bookings, :cancelled_by_id)
    remove_column :bookings, :cancelled_at if column_exists?(:bookings, :cancelled_at)
    remove_column :bookings, :cancellation_fee_percentage if column_exists?(:bookings, :cancellation_fee_percentage)
    remove_column :bookings, :cancellation_deadline_hours if column_exists?(:bookings, :cancellation_deadline_hours)
    remove_column :bookings, :cancellation_policy if column_exists?(:bookings, :cancellation_policy)
  end
end
