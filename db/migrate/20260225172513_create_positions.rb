class CreatePositions < ActiveRecord::Migration[8.1]
  def change
    create_table :positions do |t|
      t.string :name
      t.text :description
      t.integer :rank
      t.references :instance, null: false, foreign_key: true
      t.boolean :deleted

      t.timestamps
    end
  end
end
