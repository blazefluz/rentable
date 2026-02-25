class CreateProductAssetFlags < ActiveRecord::Migration[8.1]
  def change
    create_table :product_asset_flags do |t|
      t.references :product, null: false, foreign_key: true
      t.references :asset_flag, null: false, foreign_key: true

      t.timestamps
    end
  end
end
