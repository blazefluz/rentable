class CreateNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :notes do |t|
      t.references :notable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.string :title
      t.text :content
      t.integer :note_type
      t.boolean :pinned
      t.boolean :deleted

      t.timestamps
    end
  end
end
