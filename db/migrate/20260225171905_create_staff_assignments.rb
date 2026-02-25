class CreateStaffAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :staff_assignments do |t|
      t.references :staff_role, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :booking, null: false, foreign_key: true
      t.datetime :start_date
      t.datetime :end_date
      t.integer :status
      t.text :notes
      t.boolean :deleted

      t.timestamps
    end
  end
end
