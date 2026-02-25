class CreateInsuranceCertificates < ActiveRecord::Migration[8.1]
  def change
    create_table :insurance_certificates do |t|
      t.references :product, null: false, foreign_key: true
      t.string :policy_number
      t.string :provider
      t.integer :coverage_amount_cents
      t.string :coverage_amount_currency
      t.date :start_date
      t.date :end_date
      t.string :certificate_file
      t.text :notes
      t.boolean :deleted

      t.timestamps
    end
  end
end
