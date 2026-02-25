class CreatePricingRules < ActiveRecord::Migration[8.1]
  def change
    create_table :pricing_rules do |t|
      t.references :product, null: false, foreign_key: true
      t.references :product_type, null: false, foreign_key: true
      t.integer :rule_type
      t.string :name
      t.date :start_date
      t.date :end_date
      t.integer :day_of_week
      t.integer :min_days
      t.integer :max_days
      t.decimal :discount_percentage
      t.integer :price_override_cents
      t.string :price_override_currency
      t.boolean :active
      t.integer :priority
      t.boolean :deleted

      t.timestamps
    end
  end
end
