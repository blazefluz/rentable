class CreateLocationTransfers < ActiveRecord::Migration[8.1]
  def change
    create_table :location_transfers do |t|
      t.references :from_location, null: false, foreign_key: { to_table: :locations }
      t.references :to_location, null: false, foreign_key: { to_table: :locations }
      t.references :initiated_by, null: true, foreign_key: { to_table: :users }
      t.references :completed_by, null: true, foreign_key: { to_table: :users }
      t.references :booking_line_item, null: true, foreign_key: true
      t.references :booking, null: true, foreign_key: true
      t.integer :transfer_type, null: false, default: 0
      t.integer :status, null: false, default: 0
      t.datetime :initiated_at
      t.datetime :completed_at
      t.datetime :in_transit_at
      t.datetime :expected_arrival_at
      t.text :notes
      t.string :tracking_number
      t.string :carrier
      t.boolean :deleted, default: false

      t.timestamps
    end

    # Note: indexes for references are automatically created
    add_index :location_transfers, :status
    add_index :location_transfers, :transfer_type
    add_index :location_transfers, [:from_location_id, :status]
    add_index :location_transfers, [:to_location_id, :status]
    add_index :location_transfers, :deleted
  end
end
