class CreateEmailCampaigns < ActiveRecord::Migration[8.1]
  def change
    create_table :email_campaigns, id: :uuid do |t|
      t.string :name
      t.integer :campaign_type
      t.integer :status
      t.references :company, null: false, foreign_key: true, type: :bigint
      t.jsonb :trigger_conditions
      t.integer :delay_hours
      t.boolean :active
      t.datetime :starts_at
      t.datetime :ends_at

      t.timestamps
    end
  end
end
