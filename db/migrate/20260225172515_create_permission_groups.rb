class CreatePermissionGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :permission_groups do |t|
      t.string :name
      t.jsonb :permissions
      t.references :instance, null: false, foreign_key: true
      t.boolean :deleted

      t.timestamps
    end
  end
end
