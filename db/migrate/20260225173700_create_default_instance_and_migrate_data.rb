class CreateDefaultInstanceAndMigrateData < ActiveRecord::Migration[8.1]
  def up
    # Create default instance
    default_instance = Instance.create!(
      name: 'Default Organization',
      subdomain: 'default',
      active: true,
      settings: {
        created_by_migration: true,
        migration_date: Time.current
      }
    )
    
    puts "Created default instance: #{default_instance.id}"
    
    # Update all existing records to belong to default instance
    # This ensures no data is lost during multi-tenant migration
    
    update_table_with_instance('products', default_instance.id)
    update_table_with_instance('kits', default_instance.id)
    update_table_with_instance('bookings', default_instance.id)
    update_table_with_instance('clients', default_instance.id)
    update_table_with_instance('locations', default_instance.id)
    update_table_with_instance('manufacturers', default_instance.id)
    update_table_with_instance('product_types', default_instance.id)
    update_table_with_instance('payments', default_instance.id)
    update_table_with_instance('waitlist_entries', default_instance.id)
    update_table_with_instance('maintenance_jobs', default_instance.id)
    update_table_with_instance('asset_assignments', default_instance.id)
    update_table_with_instance('asset_flags', default_instance.id)
    update_table_with_instance('asset_groups', default_instance.id)
    update_table_with_instance('project_types', default_instance.id)
    update_table_with_instance('staff_roles', default_instance.id)
    update_table_with_instance('business_entities', default_instance.id)
    update_table_with_instance('sales_tasks', default_instance.id)
    
    # Update users without instance to belong to default instance
    execute "UPDATE users SET instance_id = #{default_instance.id} WHERE instance_id IS NULL"
    
    puts "Migration complete. All existing data assigned to default instance."
  end
  
  def down
    # Remove default instance (this won't delete the data)
    Instance.find_by(subdomain: 'default')&.destroy
  end
  
  private
  
  def update_table_with_instance(table_name, instance_id)
    # Check if table exists and has instance_id column
    if ActiveRecord::Base.connection.table_exists?(table_name) && 
       ActiveRecord::Base.connection.column_exists?(table_name, :instance_id)
      count = execute("UPDATE #{table_name} SET instance_id = #{instance_id} WHERE instance_id IS NULL").cmd_tuples
      puts "Updated #{count} records in #{table_name}"
    end
  end
end
