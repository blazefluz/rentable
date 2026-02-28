class CreateExpenseBudgets < ActiveRecord::Migration[8.1]
  def change
    create_table :expense_budgets, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :bigint
      t.integer :category
      t.integer :period_type
      t.integer :budgeted_amount_cents
      t.string :budgeted_amount_currency
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end
