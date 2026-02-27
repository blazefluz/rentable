class AddHasVariantsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :has_variants, :boolean, default: false, null: false
    add_index :products, :has_variants
  end
end
