class AddCompanyIdToTables < ActiveRecord::Migration[8.1]
  def change
    # Core tables that need company_id
    tables_to_update = [
      :users,
      :products,
      :kits,
      :bookings,
      :clients,
      :locations,
      :product_types,
      :pricing_rules,
      :tax_rates,
      :contracts,
      :product_bundles,
      :product_collections,
      :recurring_bookings,
      :booking_templates,
      :leads,
      :asset_groups,
      :maintenance_jobs,
      :product_instances,
      :product_accessories,
      :damage_reports,
      :insurance_certificates,
      :asset_assignments,
      :asset_flags,
      :asset_logs,
      :addresses,
      :business_entities,
      :contacts,
      :client_communications,
      :client_tags,
      :client_surveys,
      :service_agreements,
      :location_transfers,
      :permission_groups,
      :positions,
      :user_certifications,
      :sales_tasks,
      :invitation_codes,
      :manufacturers,
      :project_types,
      :staff_roles,
      :email_queues
    ]

    tables_to_update.each do |table|
      if table_exists?(table) && !column_exists?(table, :company_id)
        add_reference table, :company, foreign_key: true, index: true
      end
    end
  end
end
