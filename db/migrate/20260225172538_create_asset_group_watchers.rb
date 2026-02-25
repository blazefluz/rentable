class CreateAssetGroupWatchers < ActiveRecord::Migration[8.1]
  def change
    create_table :asset_group_watchers do |t|
      t.references :user, null: false, foreign_key: true
      t.references :asset_group, null: false, foreign_key: true
      t.boolean :notify_on_change
      t.boolean :deleted

      t.timestamps
    end
  end
end
