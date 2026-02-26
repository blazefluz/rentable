class CreateClientTaggings < ActiveRecord::Migration[8.1]
  def change
    create_table :client_taggings do |t|
      t.references :client, null: false, foreign_key: true
      t.references :client_tag, null: false, foreign_key: true
      t.bigint :tagged_by_id
      t.datetime :tagged_at

      t.timestamps
    end
  end
end
