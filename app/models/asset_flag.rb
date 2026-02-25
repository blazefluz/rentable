class AssetFlag < ApplicationRecord
  has_many :product_asset_flags, dependent: :destroy
  has_many :products, through: :product_asset_flags

  scope :active, -> { where(deleted: [false, nil]) }
  scope :deleted, -> { where(deleted: true) }

  validates :name, presence: true, uniqueness: true
  validates :color, format: { with: /\A#(?:[0-9a-fA-F]{3}){1,2}\z/, message: "must be a valid hex color" }, allow_blank: true

  after_initialize :set_defaults

  private

  def set_defaults
    self.deleted ||= false
    self.color ||= '#3b82f6' # Default blue
  end
end
