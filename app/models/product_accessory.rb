class ProductAccessory < ApplicationRecord
  include ActsAsTenant

  # Audit trail
  has_paper_trail

  # Associations
  belongs_to :product
  belongs_to :accessory, class_name: "Product"

  # Enums
  enum :accessory_type, {
    suggested: 0,      # Optional suggestion
    recommended: 1,    # Recommended for best experience
    required: 2,       # Must be included
    bundled: 3        # Automatically included
  }, prefix: true

  # Validations
  validates :product_id, uniqueness: { scope: :accessory_id }
  validates :default_quantity, numericality: { greater_than: 0 }
  validate :accessory_is_not_self

  # Scopes
  scope :required_accessories, -> { where(required: true).or(where(accessory_type: :required)) }
  scope :optional_accessories, -> { where(required: false, accessory_type: [:suggested, :recommended]) }
  scope :bundled_accessories, -> { where(accessory_type: :bundled) }

  private

  def accessory_is_not_self
    if product_id == accessory_id
      errors.add(:accessory_id, "cannot be the same as the product")
    end
  end
end
