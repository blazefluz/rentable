class AddSearchFieldsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :tags, :string, array: true, default: []
    add_column :products, :model_number, :string
    add_column :products, :specifications, :jsonb, default: {}
    add_column :products, :featured, :boolean, default: false
    add_column :products, :popularity_score, :integer, default: 0

    add_index :products, :tags, using: :gin
    add_index :products, :specifications, using: :gin
    add_index :products, :model_number
    add_index :products, :featured
    add_index :products, :popularity_score
  end
end
