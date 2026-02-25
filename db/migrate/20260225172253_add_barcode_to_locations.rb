class AddBarcodeToLocations < ActiveRecord::Migration[8.1]
  def change
    add_column :locations, :barcode, :string
    add_index :locations, :barcode, unique: true
  end
end
