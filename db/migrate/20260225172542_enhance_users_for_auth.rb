class EnhanceUsersForAuth < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :reset_password_token, :string
    add_column :users, :reset_password_sent_at, :datetime
    add_column :users, :email_verified_at, :datetime
    add_column :users, :verification_token, :string
    add_column :users, :suspended, :boolean, default: false
    add_column :users, :suspended_at, :datetime
    add_column :users, :suspended_reason, :text
    add_column :users, :social_links, :jsonb
    add_reference :users, :instance, foreign_key: true
    add_reference :users, :permission_group, foreign_key: true

    add_index :users, :reset_password_token, unique: true
    add_index :users, :verification_token, unique: true
  end
end
