class CreateEmailQueues < ActiveRecord::Migration[8.1]
  def change
    create_table :email_queues do |t|
      t.string :recipient
      t.string :subject
      t.text :body
      t.integer :status
      t.datetime :sent_at
      t.text :error_message
      t.integer :attempts
      t.datetime :last_attempt_at
      t.references :instance, null: false, foreign_key: true
      t.jsonb :metadata

      t.timestamps
    end
  end
end
