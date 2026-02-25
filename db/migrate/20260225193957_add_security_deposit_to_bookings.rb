class AddSecurityDepositToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :security_deposit_cents, :integer
    add_column :bookings, :security_deposit_currency, :string, default: "USD"
    add_column :bookings, :security_deposit_status, :integer, default: 0
    add_column :bookings, :security_deposit_refunded_at, :datetime

    add_index :bookings, :security_deposit_status
  end
end
