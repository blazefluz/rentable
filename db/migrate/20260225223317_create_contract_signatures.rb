class CreateContractSignatures < ActiveRecord::Migration[8.1]
  def change
    create_table :contract_signatures do |t|
      t.references :contract, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.string :signer_name, null: false
      t.string :signer_email, null: false
      t.integer :signer_role, null: false, default: 0
      t.text :signature_data
      t.integer :signature_type, null: false, default: 0
      t.string :ip_address
      t.string :user_agent
      t.datetime :signed_at
      t.boolean :accepted_terms, default: false
      t.string :terms_version
      t.string :witness_name
      t.text :witness_signature
      t.boolean :deleted, default: false

      t.timestamps
    end

    add_index :contract_signatures, :signer_email
    add_index :contract_signatures, :signer_role
    add_index :contract_signatures, :signature_type
    add_index :contract_signatures, :signed_at
    add_index :contract_signatures, :accepted_terms
    add_index :contract_signatures, :deleted
    add_index :contract_signatures, [:contract_id, :signer_role], name: 'index_contract_signatures_on_contract_and_role'
  end
end
