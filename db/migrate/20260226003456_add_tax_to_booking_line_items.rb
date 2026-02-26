class AddTaxToBookingLineItems < ActiveRecord::Migration[8.1]
  def change
    add_column :booking_line_items, :tax_rate_id, :bigint
    add_column :booking_line_items, :tax_amount_cents, :integer
    add_column :booking_line_items, :tax_amount_currency, :string
    add_column :booking_line_items, :taxable, :boolean
  end
end
