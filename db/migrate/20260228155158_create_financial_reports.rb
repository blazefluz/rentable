class CreateFinancialReports < ActiveRecord::Migration[8.1]
  def change
    create_table :financial_reports, id: :uuid do |t|
      t.references :company, null: false, foreign_key: true, type: :bigint
      t.integer :report_type
      t.integer :period_type
      t.date :start_date
      t.date :end_date
      t.jsonb :data
      t.datetime :generated_at
      t.references :generated_by, null: false, foreign_key: { to_table: :users }, type: :bigint

      t.timestamps
    end
  end
end
