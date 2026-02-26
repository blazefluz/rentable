class CreateClientUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :client_users do |t|
      t.references :client, null: false, foreign_key: true
      t.references :contact, null: false, foreign_key: true
      t.string :email
      t.string :encrypted_password
      t.string :password_reset_token
      t.datetime :password_reset_sent_at
      t.datetime :last_sign_in_at
      t.integer :sign_in_count
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip
      t.datetime :confirmed_at
      t.string :confirmation_token
      t.datetime :confirmation_sent_at
      t.boolean :active

      t.timestamps
    end
  end
end
