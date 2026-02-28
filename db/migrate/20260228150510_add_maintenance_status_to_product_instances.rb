class AddMaintenanceStatusToProductInstances < ActiveRecord::Migration[8.1]
  def change
    add_column :product_instances, :maintenance_status, :integer
    add_column :product_instances, :maintenance_override_by_id, :bigint
    add_column :product_instances, :maintenance_override_reason, :text
    add_column :product_instances, :maintenance_override_at, :datetime
  end
end
