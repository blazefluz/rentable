class AddSegmentationToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :industry, :string
    add_column :clients, :company_size, :string
    add_column :clients, :service_tier, :string
    add_column :clients, :market_segment, :string
    add_column :clients, :priority_level, :integer
    add_column :clients, :account_manager_id, :bigint
    add_column :clients, :custom_fields, :jsonb
  end
end
