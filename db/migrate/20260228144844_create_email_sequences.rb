class CreateEmailSequences < ActiveRecord::Migration[8.1]
  def change
    create_table :email_sequences, id: :uuid do |t|
      t.references :email_campaign, null: false, foreign_key: true, type: :uuid
      t.integer :sequence_number
      t.text :subject_template
      t.text :body_template
      t.integer :send_delay_hours
      t.boolean :active

      t.timestamps
    end
  end
end
