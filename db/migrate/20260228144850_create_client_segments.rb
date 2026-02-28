class CreateClientSegments < ActiveRecord::Migration[8.1]
  def change
    create_table :client_segments, id: :uuid do |t|
      t.string :name
      t.text :description
      t.references :company, null: false, foreign_key: true, type: :bigint
      t.jsonb :filter_rules
      t.boolean :auto_update
      t.boolean :active

      t.timestamps
    end
  end
end
