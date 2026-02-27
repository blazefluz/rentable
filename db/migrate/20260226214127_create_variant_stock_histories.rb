class CreateVariantStockHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :variant_stock_histories, id: :uuid do |t|
      t.references :product_variant, null: false, foreign_key: true, type: :uuid, index: true
      t.references :company, null: false, foreign_key: true, index: true
      t.references :user, foreign_key: true, index: true # Who made the change

      # Change details
      t.string :change_type, null: false # 'adjustment', 'sale', 'return', 'damage', 'restock', 'reservation', 'release'
      t.integer :quantity_before, null: false, default: 0
      t.integer :quantity_after, null: false, default: 0
      t.integer :quantity_change, null: false # Can be positive or negative

      # Context
      t.string :reason # Human-readable reason
      t.string :reference_type # Polymorphic - 'Booking', 'PurchaseOrder', etc.
      t.bigint :reference_id   # ID of the related record

      # Location (if applicable)
      t.references :location, foreign_key: true

      # Metadata
      t.jsonb :metadata # Additional context (batch number, damage details, etc.)

      t.timestamps
    end

    # Indexes for performance
    add_index :variant_stock_histories, [:product_variant_id, :created_at]
    add_index :variant_stock_histories, [:company_id, :created_at]
    add_index :variant_stock_histories, [:user_id, :created_at]
    add_index :variant_stock_histories, :change_type
    add_index :variant_stock_histories, [:reference_type, :reference_id], name: 'index_variant_stock_histories_on_reference'

    # For auditing - find all changes in a date range
    add_index :variant_stock_histories, :created_at
  end
end
