class Manufacturer < ApplicationRecord
  # Associations
  has_many :product_types, dependent: :destroy
  has_many :products, through: :product_types

  # Validations
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # Scopes
  scope :search, ->(query) { where("name ILIKE ?", "%#{query}%") if query.present? }
end
