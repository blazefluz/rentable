class AddFinancialMetricsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :accumulated_revenue_cents, :integer unless column_exists?(:products, :accumulated_revenue_cents)
    add_column :products, :accumulated_revenue_currency, :string unless column_exists?(:products, :accumulated_revenue_currency)
    add_column :products, :accumulated_maintenance_cost_cents, :integer unless column_exists?(:products, :accumulated_maintenance_cost_cents)
    add_column :products, :accumulated_maintenance_cost_currency, :string unless column_exists?(:products, :accumulated_maintenance_cost_currency)
    add_column :products, :depreciation_method, :integer unless column_exists?(:products, :depreciation_method)
    # depreciation_rate already exists in schema, skip it
    add_column :products, :residual_value_cents, :integer unless column_exists?(:products, :residual_value_cents)
  end
end
