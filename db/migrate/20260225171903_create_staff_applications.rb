class CreateStaffApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :staff_applications do |t|
      t.references :staff_role, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status
      t.text :notes
      t.datetime :applied_at
      t.datetime :reviewed_at
      t.references :reviewer, foreign_key: { to_table: :users }
      t.boolean :deleted

      t.timestamps
    end
  end
end
