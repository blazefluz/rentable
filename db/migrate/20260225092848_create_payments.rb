class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments do |t|
      t.references :booking, null: false, foreign_key: true
      t.integer :amount_cents, null: false
      t.string :amount_currency, default: "USD", null: false
      t.integer :payment_type, null: false
      t.integer :quantity, default: 1, null: false
      t.string :reference
      t.datetime :payment_date, default: -> { 'CURRENT_TIMESTAMP' }
      t.string :supplier
      t.string :payment_method
      t.text :comment
      t.boolean :deleted, default: false, null: false

      t.timestamps
    end

    add_index :payments, :payment_type
    add_index :payments, :payment_date
    add_index :payments, :deleted
  end
end
