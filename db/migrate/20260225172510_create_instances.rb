class CreateInstances < ActiveRecord::Migration[8.1]
  def change
    create_table :instances do |t|
      t.string :name
      t.string :subdomain
      t.jsonb :settings
      t.boolean :active
      t.references :owner, foreign_key: { to_table: :users }
      t.boolean :deleted

      t.timestamps
    end
  end
end
