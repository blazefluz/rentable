class CreateClientSurveys < ActiveRecord::Migration[8.1]
  def change
    create_table :client_surveys do |t|
      t.references :client, null: false, foreign_key: true
      t.references :booking, null: false, foreign_key: true
      t.integer :survey_type
      t.integer :nps_score
      t.integer :satisfaction_score
      t.text :feedback
      t.boolean :would_recommend
      t.datetime :survey_sent_at
      t.datetime :survey_completed_at
      t.integer :response_time_hours

      t.timestamps
    end
  end
end
