class CreateContracts < ActiveRecord::Migration[8.1]
  def change
    create_table :contracts do |t|
      t.references :booking, null: true, foreign_key: true
      t.integer :contract_type, null: false, default: 0
      t.string :title, null: false
      t.text :content
      t.string :version, default: '1.0'
      t.date :effective_date
      t.date :expiry_date
      t.integer :status, null: false, default: 0
      t.string :terms_url
      t.string :pdf_file
      t.boolean :requires_signature, default: true
      t.boolean :template, default: false
      t.string :template_name
      t.jsonb :variables, default: {}
      t.boolean :deleted, default: false

      t.timestamps
    end

    add_index :contracts, :contract_type
    add_index :contracts, :status
    add_index :contracts, :template
    add_index :contracts, :template_name
    add_index :contracts, :effective_date
    add_index :contracts, :deleted
  end
end
