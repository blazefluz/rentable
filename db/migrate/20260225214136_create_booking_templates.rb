class CreateBookingTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :booking_templates do |t|
      t.string :name, null: false
      t.text :description
      t.integer :template_type, null: false, default: 0
      t.jsonb :booking_data, default: {}
      t.references :client, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.string :category
      t.string :tags, array: true, default: []
      t.boolean :is_public, default: false
      t.boolean :favorite, default: false
      t.integer :usage_count, default: 0
      t.datetime :last_used_at
      t.boolean :deleted, default: false
      t.boolean :archived, default: false
      t.integer :estimated_duration_days, default: 1
      t.string :thumbnail_url

      t.timestamps
    end

    add_index :booking_templates, :template_type
    add_index :booking_templates, :category
    add_index :booking_templates, :is_public
    add_index :booking_templates, :favorite
    add_index :booking_templates, :deleted
    add_index :booking_templates, :archived
    add_index :booking_templates, :tags, using: :gin
    add_index :booking_templates, [:client_id, :deleted]
    add_index :booking_templates, [:created_by_id, :deleted]
  end
end
