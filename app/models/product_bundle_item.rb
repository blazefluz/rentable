class ProductBundleItem < ApplicationRecord
  # Associations
  belongs_to :product_bundle
  belongs_to :product

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :product_id, uniqueness: { scope: :product_bundle_id }
  validates :position, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :required, -> { where(required: true) }
  scope :optional, -> { where(required: false) }
  scope :ordered, -> { order(position: :asc) }

  # Callbacks
  before_validation :set_position, on: :create

  private

  def set_position
    return if position.present?
    max_position = product_bundle.product_bundle_items.maximum(:position) || -1
    self.position = max_position + 1
  end
end
