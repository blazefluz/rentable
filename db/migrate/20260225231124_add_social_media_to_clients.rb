class AddSocialMediaToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :linkedin_url, :string
    add_column :clients, :facebook_url, :string
    add_column :clients, :twitter_handle, :string
    add_column :clients, :instagram_handle, :string
    add_column :clients, :website_url, :string
  end
end
