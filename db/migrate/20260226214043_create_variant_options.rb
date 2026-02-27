class CreateVariantOptions < ActiveRecord::Migration[8.1]
  def change
    create_table :variant_options, id: :uuid do |t|
      t.references :product_variant, null: false, foreign_key: true, type: :uuid, index: true
      t.references :company, null: false, foreign_key: true, index: true

      # Option details
      t.string :option_name, null: false  # e.g., "color", "size", "storage"
      t.string :option_value, null: false # e.g., "Red", "Large", "128GB"

      # Display
      t.integer :position, default: 0 # Sort order within the variant

      # Metadata
      t.jsonb :metadata # Additional flexible data (hex color codes, size charts, etc.)

      t.timestamps
    end

    # Indexes for performance
    add_index :variant_options, [:product_variant_id, :option_name],
              unique: true,
              name: 'index_variant_options_on_variant_and_name'

    add_index :variant_options, [:product_variant_id, :position]
    add_index :variant_options, [:company_id, :option_name]
    add_index :variant_options, :option_name # For filtering by option type

    # Support for querying by option value (e.g., find all "Red" variants)
    add_index :variant_options, [:option_name, :option_value]
  end
end
