class AddEmailMetricsToEmailQueues < ActiveRecord::Migration[8.1]
  def change
    add_column :email_queues, :delivered_at, :datetime unless column_exists?(:email_queues, :delivered_at)
    add_column :email_queues, :opened_at, :datetime unless column_exists?(:email_queues, :opened_at)
    add_column :email_queues, :clicked_at, :datetime unless column_exists?(:email_queues, :clicked_at)
    add_column :email_queues, :bounced_at, :datetime unless column_exists?(:email_queues, :bounced_at)
    add_column :email_queues, :unsubscribed_at, :datetime unless column_exists?(:email_queues, :unsubscribed_at)
    add_column :email_queues, :bounce_reason, :text unless column_exists?(:email_queues, :bounce_reason)
    add_column :email_queues, :email_campaign_id, :uuid unless column_exists?(:email_queues, :email_campaign_id)
    add_column :email_queues, :email_sequence_id, :uuid unless column_exists?(:email_queues, :email_sequence_id)
    add_index :email_queues, :email_campaign_id unless index_exists?(:email_queues, :email_campaign_id)
    add_index :email_queues, :email_sequence_id unless index_exists?(:email_queues, :email_sequence_id)
  end
end
