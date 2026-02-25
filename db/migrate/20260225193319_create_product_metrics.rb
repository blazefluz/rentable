class CreateProductMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :product_metrics do |t|
      t.references :product, null: false, foreign_key: true
      t.date :metric_date
      t.integer :rental_days
      t.integer :idle_days
      t.integer :revenue_cents
      t.string :revenue_currency
      t.decimal :utilization_rate
      t.integer :times_rented

      t.timestamps
    end
  end
end
