class CreateLocationHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :location_histories do |t|
      t.references :trackable, polymorphic: true, null: false
      t.references :location, null: false, foreign_key: true
      t.references :previous_location, foreign_key: { to_table: :locations }
      t.references :moved_by, foreign_key: { to_table: :users }
      t.datetime :moved_at, default: -> { 'CURRENT_TIMESTAMP' }
      t.text :notes

      t.timestamps
    end

    add_index :location_histories, [:trackable_type, :trackable_id, :moved_at]
  end
end
