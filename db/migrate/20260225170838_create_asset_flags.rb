class CreateAssetFlags < ActiveRecord::Migration[8.1]
  def change
    create_table :asset_flags do |t|
      t.string :name
      t.string :color
      t.string :icon
      t.text :description
      t.boolean :deleted

      t.timestamps
    end
  end
end
