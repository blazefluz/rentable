class CreateWaitlistEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :waitlist_entries do |t|
      t.references :bookable, polymorphic: true, null: false
      t.string :customer_name, null: false
      t.string :customer_email, null: false
      t.string :customer_phone
      t.datetime :start_date, null: false
      t.datetime :end_date, null: false
      t.integer :quantity, default: 1, null: false
      t.integer :status, default: 0, null: false
      t.datetime :notified_at
      t.text :notes

      t.timestamps
    end

    add_index :waitlist_entries, [:bookable_type, :bookable_id]
    add_index :waitlist_entries, :customer_email
    add_index :waitlist_entries, :status
  end
end
