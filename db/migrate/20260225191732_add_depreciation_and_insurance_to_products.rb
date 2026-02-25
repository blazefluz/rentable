class AddDepreciationAndInsuranceToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :purchase_date, :date
    add_column :products, :purchase_price_cents, :integer
    add_column :products, :purchase_price_currency, :string
    add_column :products, :depreciation_rate, :decimal
    add_column :products, :current_value_cents, :integer
    add_column :products, :current_value_currency, :string
    add_column :products, :last_depreciation_date, :date
    add_column :products, :replacement_cost_cents, :integer
    add_column :products, :replacement_cost_currency, :string
    add_column :products, :insurance_required, :boolean
    add_column :products, :insurance_policy_number, :string
    add_column :products, :insurance_expiry, :date
    add_column :products, :damage_waiver_available, :boolean
    add_column :products, :damage_waiver_price_cents, :integer
    add_column :products, :damage_waiver_price_currency, :string
  end
end
