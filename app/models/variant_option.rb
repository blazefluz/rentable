class VariantOption < ApplicationRecord
  include ActsAsTenant

  # Multi-tenancy
  acts_as_tenant :company

  # Associations
  belongs_to :product_variant
  belongs_to :company

  # Validations
  validates :option_name, presence: true
  validates :option_value, presence: true
  validates :option_name, uniqueness: { scope: :product_variant_id, message: "can only appear once per variant" }
  validates :position, numericality: { greater_than_or_equal_to: 0 }

  validate :option_name_format
  validate :option_value_format

  # Callbacks
  before_validation :normalize_option_name
  before_validation :set_position, if: :new_record?

  # Scopes
  scope :by_position, -> { order(position: :asc) }
  scope :by_name, ->(name) { where(option_name: name) }
  scope :by_value, ->(value) { where(option_value: value) }

  # Common option names for validation
  COMMON_OPTIONS = %w[
    size
    color
    colour
    material
    style
    pattern
    finish
    capacity
    storage
    memory
    speed
    length
    width
    height
    weight
    flavor
    flavour
    scent
    fit
    model
    version
  ].freeze

  # Display helpers
  def display_text
    "#{option_name.titleize}: #{option_value}"
  end

  def to_s
    display_text
  end

  # Metadata helpers
  def hex_color
    metadata&.dig('hex_color')
  end

  def hex_color=(value)
    self.metadata ||= {}
    self.metadata['hex_color'] = value
  end

  def image_url
    metadata&.dig('image_url')
  end

  def image_url=(value)
    self.metadata ||= {}
    self.metadata['image_url'] = value
  end

  def size_chart_data
    metadata&.dig('size_chart')
  end

  def size_chart_data=(value)
    self.metadata ||= {}
    self.metadata['size_chart'] = value
  end

  private

  def normalize_option_name
    # Normalize option names to lowercase for consistency
    self.option_name = option_name.to_s.strip.downcase if option_name.present?
  end

  def option_name_format
    return if option_name.blank?

    # Allow letters, numbers, underscores, and hyphens
    unless option_name.match?(/\A[a-z0-9_-]+\z/)
      errors.add(:option_name, "can only contain lowercase letters, numbers, underscores, and hyphens")
    end

    # Limit length
    if option_name.length > 50
      errors.add(:option_name, "is too long (maximum is 50 characters)")
    end
  end

  def option_value_format
    return if option_value.blank?

    # Limit length
    if option_value.length > 100
      errors.add(:option_value, "is too long (maximum is 100 characters)")
    end
  end

  def set_position
    # Auto-set position to be last
    max_position = product_variant.variant_options.maximum(:position) || -1
    self.position = max_position + 1
  end
end
