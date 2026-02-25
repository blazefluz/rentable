class CreateBookingComments < ActiveRecord::Migration[8.1]
  def change
    create_table :booking_comments do |t|
      t.references :booking, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.boolean :deleted, default: false, null: false

      t.timestamps
    end

    add_index :booking_comments, :deleted
    add_index :booking_comments, :created_at
  end
end
