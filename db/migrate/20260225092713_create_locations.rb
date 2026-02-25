class CreateLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :locations do |t|
      t.string :name, null: false
      t.text :address
      t.text :notes
      t.boolean :deleted, default: false, null: false
      t.boolean :archived, default: false, null: false
      t.references :client, null: true, foreign_key: true
      t.bigint :parent_id, null: true

      t.timestamps
    end

    add_foreign_key :locations, :locations, column: :parent_id
    add_index :locations, :parent_id
    add_index :locations, :deleted
    add_index :locations, :archived
  end
end
