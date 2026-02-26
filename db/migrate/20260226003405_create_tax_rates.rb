class CreateTaxRates < ActiveRecord::Migration[8.1]
  def change
    create_table :tax_rates do |t|
      t.string :name
      t.string :tax_code
      t.integer :tax_type
      t.integer :calculation_method
      t.decimal :rate
      t.string :country
      t.string :state
      t.string :city
      t.string :zip_code_pattern
      t.boolean :active
      t.date :start_date
      t.date :end_date
      t.boolean :applies_to_shipping
      t.boolean :applies_to_deposits
      t.integer :minimum_amount_cents
      t.integer :maximum_amount_cents
      t.boolean :compound
      t.integer :position
      t.integer :rate_cents

      t.timestamps
    end
    add_index :tax_rates, :tax_code, unique: true
  end
end
