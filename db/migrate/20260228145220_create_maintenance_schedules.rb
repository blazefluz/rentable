class CreateMaintenanceSchedules < ActiveRecord::Migration[8.1]
  def change
    create_table :maintenance_schedules do |t|
      t.references :product, null: false, foreign_key: true, type: :bigint
      t.references :company, null: false, foreign_key: true, type: :bigint
      t.references :assigned_to, foreign_key: { to_table: :users }, type: :bigint, null: true

      t.string :name, null: false
      t.text :description

      # Frequency configuration
      t.string :frequency, null: false
      t.integer :interval_value, null: false
      t.string :interval_unit, null: false

      # Scheduling
      t.datetime :last_completed_at
      t.datetime :next_due_date

      # Status
      t.string :status, default: 'scheduled'
      t.boolean :enabled, default: true

      t.timestamps
    end

    # Additional indexes beyond the ones created by t.references
    add_index :maintenance_schedules, [:next_due_date, :enabled], where: "enabled = true", name: 'index_maintenance_schedules_on_next_due_enabled'
    add_index :maintenance_schedules, :status
  end
end
