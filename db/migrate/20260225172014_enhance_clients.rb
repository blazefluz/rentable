class EnhanceClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :account_value_cents, :integer
    add_column :clients, :account_value_currency, :string, default: 'USD'
    add_column :clients, :priority, :integer, default: 1
    add_column :clients, :position, :integer
  end
end
