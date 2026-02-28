class CreateExpenses < ActiveRecord::Migration[8.1]
  def change
    create_table :expenses, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :bigint
      t.integer :category
      t.integer :amount_cents
      t.string :amount_currency
      t.date :date
      t.string :vendor
      t.string :invoice_number
      t.text :description
      t.text :notes
      t.string :payment_method
      t.date :payment_date

      t.timestamps
    end
  end
end
