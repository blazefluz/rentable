class AddItemTypeToProducts < ActiveRecord::Migration[8.1]
  def change
    # Item type: rental (0), sale (1), service (2)
    add_column :products, :item_type, :integer, default: 0, null: false
    add_index :products, :item_type

    # Sale price for sale items
    add_column :products, :sale_price_cents, :integer
    add_column :products, :sale_price_currency, :string, default: 'USD'

    # Inventory tracking for sale items
    add_column :products, :tracks_inventory, :boolean, default: false
    add_column :products, :stock_on_hand, :integer, default: 0
    add_column :products, :reorder_point, :integer
    add_index :products, :stock_on_hand
    add_index :products, [:item_type, :tracks_inventory]
  end
end
