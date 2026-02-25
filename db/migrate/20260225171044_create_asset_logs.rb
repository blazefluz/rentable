class CreateAssetLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :asset_logs do |t|
      t.references :product, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :log_type
      t.text :description
      t.jsonb :metadata
      t.datetime :logged_at

      t.timestamps
    end
  end
end
