class CreateAssetGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :asset_groups do |t|
      t.string :name
      t.text :description
      t.boolean :deleted

      t.timestamps
    end
  end
end
