class CreateCompanies < ActiveRecord::Migration[8.1]
  def change
    create_table :companies do |t|
      t.string :name, null: false
      t.string :subdomain, null: false
      t.string :custom_domain
      t.string :logo
      t.string :primary_color, default: '#3B82F6'
      t.string :secondary_color, default: '#10B981'
      t.string :timezone, default: 'UTC'
      t.string :default_currency, default: 'USD'
      t.string :business_email
      t.string :business_phone
      t.text :address
      t.jsonb :settings, default: {}
      t.integer :status, default: 0, null: false
      t.integer :subscription_tier, default: 0
      t.datetime :trial_ends_at
      t.datetime :subscription_started_at
      t.datetime :subscription_cancelled_at
      t.boolean :active, default: true, null: false
      t.boolean :deleted, default: false, null: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :companies, :subdomain, unique: true
    add_index :companies, :custom_domain, unique: true, where: "custom_domain IS NOT NULL"
    add_index :companies, :status
    add_index :companies, :active
    add_index :companies, :deleted
  end
end
