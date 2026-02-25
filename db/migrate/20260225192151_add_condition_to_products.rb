class AddConditionToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :condition, :integer, default: 0
    add_column :products, :condition_notes, :text
    add_column :products, :last_condition_check, :date
  end
end
