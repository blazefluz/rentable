class AddPasswordDigestToClientUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :client_users, :password_digest, :string
  end
end
