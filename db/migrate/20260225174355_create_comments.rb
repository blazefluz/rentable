class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :commentable, polymorphic: true, null: false
      t.references :user, null: false, foreign_key: true
      t.references :parent_comment, foreign_key: { to_table: :comments }
      t.text :content
      t.integer :upvotes_count
      t.boolean :deleted
      t.references :instance, null: false, foreign_key: true

      t.timestamps
    end
  end
end
