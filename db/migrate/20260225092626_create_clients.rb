class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.string :name, null: false
      t.string :email
      t.string :phone
      t.string :website
      t.text :address
      t.text :notes
      t.boolean :archived, default: false, null: false
      t.boolean :deleted, default: false, null: false

      t.timestamps
    end

    add_index :clients, :email
    add_index :clients, :archived
    add_index :clients, :deleted
  end
end
