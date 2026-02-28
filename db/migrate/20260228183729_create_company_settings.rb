class CreateCompanySettings < ActiveRecord::Migration[8.1]
  def change
    create_table :company_settings, id: :uuid do |t|
      t.bigint :company_id, null: false
      t.string :setting_key, null: false
      t.jsonb :setting_value, default: {}
      t.integer :setting_type, default: 0, null: false
      t.text :description
      t.jsonb :default_value, default: {}
      t.boolean :editable, default: true, null: false
      t.string :category, default: 'general'

      t.timestamps
    end

    add_foreign_key :company_settings, :companies
    add_index :company_settings, [:company_id, :setting_key], unique: true
    add_index :company_settings, :category
    add_index :company_settings, :setting_type
  end
end
