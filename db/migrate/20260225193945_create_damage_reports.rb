class CreateDamageReports < ActiveRecord::Migration[8.1]
  def change
    create_table :damage_reports do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.references :reported_by, null: false, foreign_key: { to_table: :users }
      t.integer :severity, default: 0
      t.text :description
      t.integer :repair_cost_cents
      t.string :repair_cost_currency
      t.boolean :resolved, default: false
      t.datetime :resolved_at
      t.text :resolution_notes

      t.timestamps
    end

    add_index :damage_reports, :resolved
    add_index :damage_reports, :severity
  end
end
