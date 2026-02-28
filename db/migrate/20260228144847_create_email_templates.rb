class CreateEmailTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :email_templates, id: :uuid do |t|
      t.string :name
      t.integer :category
      t.references :company, null: false, foreign_key: true, type: :bigint
      t.string :subject
      t.text :html_body
      t.text :text_body
      t.jsonb :variable_schema
      t.boolean :active

      t.timestamps
    end
  end
end
