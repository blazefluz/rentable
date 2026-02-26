class AddCreditTermsToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :credit_limit_cents, :integer
    add_column :clients, :credit_limit_currency, :string
    add_column :clients, :payment_terms_days, :integer
    add_column :clients, :payment_method, :string
    add_column :clients, :credit_status, :integer
    add_column :clients, :outstanding_balance_cents, :integer
    add_column :clients, :outstanding_balance_currency, :string
    add_column :clients, :requires_deposit, :boolean
    add_column :clients, :deposit_percentage, :decimal
    add_column :clients, :approved_credit_date, :date
    add_column :clients, :credit_notes, :text
  end
end
