class CreateUserCertifications < ActiveRecord::Migration[8.1]
  def change
    create_table :user_certifications do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name
      t.date :issued_date
      t.date :expiry_date
      t.string :certificate_number
      t.boolean :deleted

      t.timestamps
    end
  end
end
