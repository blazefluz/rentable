class AddInstanceToTenantResources < ActiveRecord::Migration[8.1]
  def change
    # Add instance_id to all tenant-scoped resources
    add_reference :products, :instance, foreign_key: true
    add_reference :kits, :instance, foreign_key: true
    add_reference :bookings, :instance, foreign_key: true
    add_reference :clients, :instance, foreign_key: true
    add_reference :locations, :instance, foreign_key: true
    add_reference :manufacturers, :instance, foreign_key: true
    add_reference :product_types, :instance, foreign_key: true
    add_reference :payments, :instance, foreign_key: true
    add_reference :waitlist_entries, :instance, foreign_key: true
    add_reference :maintenance_jobs, :instance, foreign_key: true
    add_reference :asset_assignments, :instance, foreign_key: true
    add_reference :asset_flags, :instance, foreign_key: true
    add_reference :asset_groups, :instance, foreign_key: true
    add_reference :project_types, :instance, foreign_key: true
    add_reference :staff_roles, :instance, foreign_key: true
    add_reference :business_entities, :instance, foreign_key: true
    add_reference :sales_tasks, :instance, foreign_key: true

    # Add indexes for common queries
    add_index :products, [:instance_id, :active]
    add_index :bookings, [:instance_id, :status]
    add_index :clients, [:instance_id, :archived]
  end
end
