class CreateClientMetrics < ActiveRecord::Migration[8.1]
  def change
    create_table :client_metrics do |t|
      t.references :client, null: false, foreign_key: true
      t.date :metric_date
      t.integer :rentals_count
      t.integer :revenue_cents
      t.string :revenue_currency
      t.integer :items_rented
      t.decimal :utilization_rate
      t.decimal :average_rental_duration

      t.timestamps
    end
  end
end
