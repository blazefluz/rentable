class CreateContacts < ActiveRecord::Migration[8.1]
  def change
    create_table :contacts do |t|
      t.references :client, null: false, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.string :title
      t.string :email
      t.string :phone
      t.string :mobile
      t.boolean :is_primary
      t.boolean :decision_maker
      t.boolean :receives_invoices
      t.text :notes

      t.timestamps
    end
  end
end
