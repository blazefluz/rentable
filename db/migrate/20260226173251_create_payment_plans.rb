class CreatePaymentPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_plans do |t|
      t.references :booking, null: false, foreign_key: true
      t.string :name
      t.text :description
      t.integer :total_amount_cents
      t.string :total_amount_currency
      t.integer :down_payment_cents
      t.string :down_payment_currency
      t.integer :installment_amount_cents
      t.string :installment_amount_currency
      t.integer :installment_frequency
      t.integer :number_of_installments
      t.integer :installments_paid
      t.date :start_date
      t.date :next_payment_date
      t.integer :status
      t.boolean :active
      t.string :payment_method
      t.text :notes

      t.timestamps
    end
  end
end
