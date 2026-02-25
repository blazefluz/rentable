class CreateUserPreferences < ActiveRecord::Migration[8.1]
  def change
    create_table :user_preferences do |t|
      t.references :user, null: false, foreign_key: true
      t.jsonb :preferences
      t.jsonb :widgets

      t.timestamps
    end
  end
end
