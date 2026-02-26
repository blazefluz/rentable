class AddTaxFieldsToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :subtotal_cents, :integer
    add_column :bookings, :subtotal_currency, :string
    add_column :bookings, :tax_total_cents, :integer
    add_column :bookings, :tax_total_currency, :string
    add_column :bookings, :grand_total_cents, :integer
    add_column :bookings, :grand_total_currency, :string
    add_column :bookings, :tax_exempt, :boolean
    add_column :bookings, :tax_exempt_reason, :text
    add_column :bookings, :tax_exempt_certificate, :string
    add_column :bookings, :tax_override, :boolean
    add_column :bookings, :tax_override_amount_cents, :integer
    add_column :bookings, :tax_override_reason, :text
    add_column :bookings, :tax_override_by_id, :bigint
    add_column :bookings, :reverse_charge_applied, :boolean
    add_column :bookings, :default_tax_rate_id, :bigint
  end
end
