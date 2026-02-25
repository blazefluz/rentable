class CreateRecurringBookings < ActiveRecord::Migration[8.1]
  def change
    create_table :recurring_bookings do |t|
      t.string :name, null: false
      t.integer :frequency, null: false, default: 0 # weekly, monthly, etc
      t.datetime :start_date, null: false
      t.datetime :end_date
      t.datetime :next_occurrence, null: false
      t.datetime :last_generated
      t.integer :occurrence_count, default: 0
      t.integer :max_occurrences
      t.boolean :active, default: true
      t.jsonb :booking_template, default: {}
      t.integer :interval, default: 1 # Every N weeks/months
      t.integer :day_of_week # For weekly: 0-6 (Sunday-Saturday)
      t.integer :day_of_month # For monthly: 1-31
      t.string :subscription_type # For subscription vs series bookings
      t.references :client, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.boolean :deleted, default: false

      t.timestamps
    end

    add_index :recurring_bookings, :frequency
    add_index :recurring_bookings, :next_occurrence
    add_index :recurring_bookings, :active
    add_index :recurring_bookings, [:active, :next_occurrence]
    add_index :recurring_bookings, :deleted
  end
end
