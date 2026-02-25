class AssetGroup < ApplicationRecord
  has_many :asset_group_products, dependent: :destroy
  has_many :products, through: :asset_group_products

  scope :active, -> { where(deleted: [false, nil]) }
  scope :deleted, -> { where(deleted: true) }

  validates :name, presence: true, uniqueness: true

  after_initialize :set_defaults

  private

  def set_defaults
    self.deleted ||= false
  end
end
