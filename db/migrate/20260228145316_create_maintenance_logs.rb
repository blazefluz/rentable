class CreateMaintenanceLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :maintenance_logs do |t|
      t.references :maintenance_schedule, null: false, foreign_key: true, type: :bigint
      t.references :performed_by, null: false, foreign_key: { to_table: :users }, type: :bigint
      t.datetime :completed_at, null: false
      t.text :notes

      t.timestamps
    end

    # Additional index beyond the one created by t.references
    add_index :maintenance_logs, :completed_at
  end
end
