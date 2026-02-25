class CreateAssetGroupProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :asset_group_products do |t|
      t.references :asset_group, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true

      t.timestamps
    end
  end
end
