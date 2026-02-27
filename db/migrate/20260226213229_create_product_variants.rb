class CreateProductVariants < ActiveRecord::Migration[8.1]
  def change
    # Enable UUID extension if not already enabled
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :product_variants, id: :uuid do |t|
      t.references :product, null: false, foreign_key: true, index: true
      t.references :company, null: false, foreign_key: true, index: true

      # Identification
      t.string :sku, null: false
      t.string :barcode
      t.string :variant_name

      # Pricing (can override product price)
      t.integer :price_cents
      t.string :price_currency, default: 'USD'
      t.integer :compare_at_price_cents # For "was $50, now $40"

      # Inventory
      t.integer :stock_quantity, null: false, default: 0
      t.integer :reserved_quantity, default: 0 # Quantity in pending bookings
      t.integer :low_stock_threshold, default: 5

      # Display
      t.integer :position, default: 0 # Sort order
      t.boolean :active, default: true
      t.boolean :featured, default: false

      # Physical attributes
      t.decimal :weight, precision: 10, scale: 2 # In kg
      t.jsonb :dimensions # { length: 10, width: 5, height: 3, unit: "cm" }

      # Metadata
      t.jsonb :custom_attributes # Extra flexible attributes

      # Soft delete
      t.boolean :deleted, default: false
      t.datetime :deleted_at

      t.timestamps
    end

    # Indexes for performance
    add_index :product_variants, :sku, unique: true
    add_index :product_variants, :barcode, unique: true, where: "barcode IS NOT NULL"
    add_index :product_variants, [:product_id, :active]
    add_index :product_variants, [:product_id, :position]
    add_index :product_variants, [:company_id, :active]
    add_index :product_variants, [:product_id, :stock_quantity], where: "stock_quantity > 0", name: 'index_variants_with_stock'
    add_index :product_variants, :deleted, where: "deleted = false"
  end
end
