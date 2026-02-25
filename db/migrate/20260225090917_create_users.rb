class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :name, null: false
      t.integer :role, null: false, default: 0
      t.string :api_token

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :api_token, unique: true, where: "api_token IS NOT NULL"
  end
end
