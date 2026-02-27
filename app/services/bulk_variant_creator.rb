# Service to create multiple product variants from a matrix of options
# Example usage:
#   BulkVariantCreator.new(product).create_matrix(
#     options: {
#       "size" => ["Small", "Medium", "Large"],
#       "color" => ["Red", "Blue", "Green"]
#     },
#     base_price_cents: 5000,
#     stock_quantity: 10
#   )
#   This would create 9 variants (3 sizes × 3 colors)

class BulkVariantCreator
  attr_reader :product, :errors, :created_variants

  def initialize(product)
    @product = product
    @errors = []
    @created_variants = []
  end

  # Create variants from a matrix of options
  # options: Hash of option_name => array of option_values
  # Example: { "size" => ["S", "M", "L"], "color" => ["Red", "Blue"] }
  def create_matrix(options:, base_price_cents: nil, stock_quantity: 0, user: nil, **attributes)
    validate_options!(options)

    # Generate all combinations
    combinations = generate_combinations(options)

    ActiveRecord::Base.transaction do
      # Enable variants on product if not already
      product.enable_variants! unless product.has_variants?

      combinations.each_with_index do |combination, index|
        variant = create_variant_from_combination(
          combination: combination,
          position: index,
          base_price_cents: base_price_cents,
          stock_quantity: stock_quantity,
          user: user,
          **attributes
        )

        if variant.persisted?
          @created_variants << variant
        else
          @errors << { combination: combination, errors: variant.errors.full_messages }
        end
      end

      # Rollback if any errors occurred
      raise ActiveRecord::Rollback if @errors.any?
    end

    @errors.empty?
  end

  # Create variants from an array of option combinations
  # combinations: Array of hashes, each representing one variant's options
  # Example: [{ "size" => "S", "color" => "Red" }, { "size" => "M", "color" => "Blue" }]
  def create_from_combinations(combinations:, base_price_cents: nil, stock_quantity: 0, user: nil, **attributes)
    validate_combinations!(combinations)

    ActiveRecord::Base.transaction do
      # Enable variants on product if not already
      product.enable_variants! unless product.has_variants?

      combinations.each_with_index do |combination, index|
        variant = create_variant_from_combination(
          combination: combination,
          position: index,
          base_price_cents: base_price_cents,
          stock_quantity: stock_quantity,
          user: user,
          **attributes
        )

        if variant.persisted?
          @created_variants << variant
        else
          @errors << { combination: combination, errors: variant.errors.full_messages }
        end
      end

      # Rollback if any errors occurred
      raise ActiveRecord::Rollback if @errors.any?
    end

    @errors.empty?
  end

  # Duplicate all variants from another product
  def duplicate_from_product(source_product, preserve_stock: false)
    ActiveRecord::Base.transaction do
      # Enable variants on product if not already
      product.enable_variants! unless product.has_variants?

      source_product.product_variants.active.each_with_index do |source_variant, index|
        variant = product.product_variants.create!(
          variant_name: source_variant.variant_name,
          price_cents: source_variant.price_cents,
          price_currency: source_variant.price_currency,
          compare_at_price_cents: source_variant.compare_at_price_cents,
          stock_quantity: preserve_stock ? source_variant.stock_quantity : 0,
          reserved_quantity: 0, # Don't copy reservations
          low_stock_threshold: source_variant.low_stock_threshold,
          position: index,
          active: source_variant.active,
          featured: source_variant.featured,
          weight: source_variant.weight,
          dimensions: source_variant.dimensions,
          custom_attributes: source_variant.custom_attributes,
          company: product.company
        )

        # Duplicate variant options
        source_variant.variant_options.each do |source_option|
          variant.variant_options.create!(
            option_name: source_option.option_name,
            option_value: source_option.option_value,
            position: source_option.position,
            metadata: source_option.metadata,
            company: product.company
          )
        end

        @created_variants << variant
      end
    end

    true
  rescue => e
    @errors << { error: e.message }
    false
  end

  # Summary of what would be created (dry run)
  def preview_matrix(options:)
    combinations = generate_combinations(options)
    {
      total_variants: combinations.count,
      option_types: options.keys,
      combinations: combinations.first(10), # Show first 10
      estimated_skus: combinations.count
    }
  end

  private

  def validate_options!(options)
    raise ArgumentError, "Options hash cannot be empty" if options.blank?

    options.each do |key, values|
      raise ArgumentError, "Option name '#{key}' cannot be blank" if key.blank?
      raise ArgumentError, "Option values for '#{key}' must be an array" unless values.is_a?(Array)
      raise ArgumentError, "Option values for '#{key}' cannot be empty" if values.empty?
    end
  end

  def validate_combinations!(combinations)
    raise ArgumentError, "Combinations array cannot be empty" if combinations.blank?
    raise ArgumentError, "Combinations must be an array of hashes" unless combinations.all? { |c| c.is_a?(Hash) }
  end

  def generate_combinations(options)
    # Convert hash to array of [key, values] pairs
    option_arrays = options.map { |key, values| values.map { |v| [key, v] } }

    # Generate cartesian product
    option_arrays[0].product(*option_arrays[1..-1]).map do |combo|
      # Flatten and convert to hash
      Array(combo).to_h
    end
  end

  def create_variant_from_combination(combination:, position:, base_price_cents:, stock_quantity:, user: nil, **attributes)
    # Generate variant name from options
    variant_name = combination.values.join(' / ')

    # Create the variant
    variant = product.product_variants.build(
      variant_name: variant_name,
      price_cents: base_price_cents,
      price_currency: product.daily_price_currency,
      stock_quantity: stock_quantity,
      position: position,
      company: product.company,
      **attributes.except(:variant_options_attributes) # Remove nested attributes if present
    )

    # SKU will be auto-generated by model callback
    variant.save

    return variant unless variant.persisted?

    # Create variant options
    combination.each_with_index do |(option_name, option_value), opt_position|
      variant.variant_options.create!(
        option_name: option_name.to_s.downcase,
        option_value: option_value,
        position: opt_position,
        company: product.company
      )
    end

    variant
  end
end
