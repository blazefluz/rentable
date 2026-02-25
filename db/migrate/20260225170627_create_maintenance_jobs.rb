class CreateMaintenanceJobs < ActiveRecord::Migration[8.1]
  def change
    create_table :maintenance_jobs do |t|
      t.references :product, null: false, foreign_key: true
      t.string :title
      t.text :description
      t.integer :status
      t.integer :priority
      t.datetime :scheduled_date
      t.datetime :completed_date
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.integer :cost_cents
      t.string :cost_currency
      t.text :notes
      t.boolean :deleted

      t.timestamps
    end
  end
end
