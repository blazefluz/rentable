class AddMaintenanceStatusToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :maintenance_status, :integer, default: 0
    add_column :products, :maintenance_override_by_id, :bigint
    add_column :products, :maintenance_override_reason, :text
    add_column :products, :maintenance_override_at, :datetime

    add_index :products, :maintenance_status
    add_foreign_key :products, :users, column: :maintenance_override_by_id
  end
end
