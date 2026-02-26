class AddCurrentSignInAtToClientUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :client_users, :current_sign_in_at, :datetime
  end
end
