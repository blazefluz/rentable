class CreateLeads < ActiveRecord::Migration[8.1]
  def change
    create_table :leads do |t|
      t.string :name
      t.string :email
      t.string :phone
      t.string :company
      t.string :source
      t.integer :status
      t.integer :expected_value_cents
      t.string :expected_value_currency
      t.integer :probability
      t.date :expected_close_date
      t.bigint :assigned_to_id
      t.bigint :converted_to_client_id
      t.datetime :converted_at
      t.text :notes
      t.text :lost_reason

      t.timestamps
    end
  end
end
