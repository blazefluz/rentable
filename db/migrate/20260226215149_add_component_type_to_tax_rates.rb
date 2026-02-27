class AddComponentTypeToTaxRates < ActiveRecord::Migration[8.1]
  def change
    add_column :tax_rates, :component_type, :integer, default: 0
    add_column :tax_rates, :parent_tax_rate_id, :bigint
    add_index :tax_rates, :parent_tax_rate_id
    add_index :tax_rates, :component_type
  end
end
