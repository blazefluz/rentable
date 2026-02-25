class EnhanceProducts < ActiveRecord::Migration[8.1]
  def change
    # Add product_type reference
    add_reference :products, :product_type, null: true, foreign_key: true, index: true

    # Add weekly pricing
    add_column :products, :weekly_price_cents, :integer, default: 0, null: false
    add_column :products, :weekly_price_currency, :string, default: "USD", null: false

    # Add asset value (replacement cost)
    add_column :products, :value_cents, :integer, default: 0, null: false

    # Add mass/weight
    add_column :products, :mass, :decimal, precision: 10, scale: 2

    # Add custom fields (JSONB for flexible data)
    add_column :products, :custom_fields, :jsonb, default: {}
    add_index :products, :custom_fields, using: :gin

    # Add asset tag
    add_column :products, :asset_tag, :string
    add_index :products, :asset_tag, unique: true, where: "(asset_tag IS NOT NULL)"

    # Add end_date (for deprecation/disposal)
    add_column :products, :end_date, :datetime

    # Add archived flag (separate from active)
    add_column :products, :archived, :boolean, default: false, null: false
    add_index :products, :archived

    # Add deleted flag (soft delete)
    add_column :products, :deleted, :boolean, default: false, null: false
    add_index :products, :deleted

    # Add show_public flag
    add_column :products, :show_public, :boolean, default: true, null: false
  end
end
