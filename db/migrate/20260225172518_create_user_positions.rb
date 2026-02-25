class CreateUserPositions < ActiveRecord::Migration[8.1]
  def change
    create_table :user_positions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :position, null: false, foreign_key: true
      t.references :instance, null: false, foreign_key: true
      t.datetime :start_date
      t.datetime :end_date
      t.boolean :active
      t.boolean :deleted

      t.timestamps
    end
  end
end
