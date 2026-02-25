class CreateKitItems < ActiveRecord::Migration[8.1]
  def change
    create_table :kit_items do |t|
      t.references :kit, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1

      t.timestamps
    end

    add_index :kit_items, [:kit_id, :product_id], unique: true
  end
end
