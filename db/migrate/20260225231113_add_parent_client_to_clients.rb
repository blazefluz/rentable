class AddParentClientToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :parent_client_id, :bigint
  end
end
