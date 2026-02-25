class EnhanceProductTypesWithColorsAndDiscounts < ActiveRecord::Migration[8.1]
  def change
    add_column :product_types, :color, :string
    add_column :product_types, :discount_percentage, :decimal, precision: 5, scale: 2
    add_column :product_types, :archived, :boolean, default: false
  end
end
