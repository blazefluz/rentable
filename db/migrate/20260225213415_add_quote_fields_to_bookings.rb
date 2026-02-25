class AddQuoteFieldsToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :quote_number, :string
    add_column :bookings, :quote_expires_at, :datetime
    add_column :bookings, :quote_status, :integer, default: 0
    add_column :bookings, :quote_sent_at, :datetime
    add_column :bookings, :quote_viewed_at, :datetime
    add_column :bookings, :quote_approved_at, :datetime
    add_column :bookings, :quote_approved_by_id, :bigint
    add_column :bookings, :quote_declined_at, :datetime
    add_column :bookings, :quote_decline_reason, :text
    add_column :bookings, :converted_from_quote, :boolean, default: false
    add_column :bookings, :quote_terms, :text
    add_column :bookings, :quote_valid_days, :integer, default: 30

    add_index :bookings, :quote_number, unique: true
    add_index :bookings, :quote_status
    add_index :bookings, :quote_expires_at
    add_index :bookings, :converted_from_quote
    add_index :bookings, :quote_approved_by_id

    add_foreign_key :bookings, :users, column: :quote_approved_by_id, on_delete: :nullify
  end
end
