class CreateScheduledReports < ActiveRecord::Migration[8.1]
  def change
    create_table :scheduled_reports, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :bigint
      t.integer :report_type
      t.integer :frequency
      t.jsonb :recipients
      t.integer :format
      t.date :next_send_date
      t.boolean :active

      t.timestamps
    end
  end
end
