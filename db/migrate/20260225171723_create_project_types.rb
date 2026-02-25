class CreateProjectTypes < ActiveRecord::Migration[8.1]
  def change
    create_table :project_types do |t|
      t.string :name
      t.text :description
      t.jsonb :feature_flags
      t.jsonb :settings
      t.boolean :active
      t.integer :default_duration_days
      t.boolean :requires_approval
      t.boolean :auto_confirm
      t.boolean :deleted

      t.timestamps
    end
  end
end
