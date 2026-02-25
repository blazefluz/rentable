class AddPricingFieldsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :weekend_price_cents, :integer
    add_column :products, :weekend_price_currency, :string
    add_column :products, :minimum_rental_days, :integer
    add_column :products, :late_fee_cents, :integer
    add_column :products, :late_fee_currency, :string
    add_column :products, :late_fee_type, :integer
  end
end
