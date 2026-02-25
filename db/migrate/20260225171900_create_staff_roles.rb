class CreateStaffRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :staff_roles do |t|
      t.string :name
      t.text :description
      t.references :booking, null: false, foreign_key: true
      t.integer :required_count
      t.integer :filled_count
      t.integer :status
      t.boolean :deleted

      t.timestamps
    end
  end
end
