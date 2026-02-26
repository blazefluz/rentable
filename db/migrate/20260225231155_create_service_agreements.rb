class CreateServiceAgreements < ActiveRecord::Migration[8.1]
  def change
    create_table :service_agreements do |t|
      t.references :client, null: false, foreign_key: true
      t.string :name
      t.integer :agreement_type
      t.date :start_date
      t.date :end_date
      t.integer :renewal_type
      t.integer :minimum_commitment_cents
      t.string :minimum_commitment_currency
      t.integer :payment_schedule
      t.decimal :discount_percentage
      t.text :notes
      t.boolean :active
      t.boolean :auto_renew

      t.timestamps
    end
  end
end
