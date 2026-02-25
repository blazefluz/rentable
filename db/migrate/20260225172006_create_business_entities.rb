class CreateBusinessEntities < ActiveRecord::Migration[8.1]
  def change
    create_table :business_entities do |t|
      t.string :name
      t.string :legal_name
      t.string :tax_id
      t.string :entity_type
      t.references :client, null: false, foreign_key: true
      t.boolean :active
      t.text :notes
      t.boolean :deleted

      t.timestamps
    end
  end
end
