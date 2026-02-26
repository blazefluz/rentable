class CreateClientCommunications < ActiveRecord::Migration[8.1]
  def change
    create_table :client_communications do |t|
      t.references :client, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.integer :communication_type
      t.integer :direction
      t.string :subject
      t.text :notes
      t.datetime :communicated_at
      t.string :attachment

      t.timestamps
    end
  end
end
