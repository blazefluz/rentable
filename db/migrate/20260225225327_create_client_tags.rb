class CreateClientTags < ActiveRecord::Migration[8.1]
  def change
    create_table :client_tags do |t|
      t.string :name
      t.string :color
      t.text :description
      t.string :icon
      t.boolean :active

      t.timestamps
    end
  end
end
