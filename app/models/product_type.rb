class ProductType < ApplicationRecord
  # Associations
  belongs_to :manufacturer, optional: true
  has_many :products, dependent: :nullify

  # Monetize
  monetize :daily_price_cents, as: :daily_price, with_model_currency: :daily_price_currency
  monetize :weekly_price_cents, as: :weekly_price, with_model_currency: :weekly_price_currency
  monetize :value_cents, as: :value, currency: :daily_price_currency

  # Validations
  validates :name, presence: true
  validates :name, uniqueness: { scope: :manufacturer_id, case_sensitive: false, allow_nil: true }
  validates :daily_price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :weekly_price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :value_cents, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :search, ->(query) { where("name ILIKE ? OR category ILIKE ?", "%#{query}%", "%#{query}%") if query.present? }

  # Get full name with manufacturer (e.g., "Canon - EOS R5")
  def full_name
    "#{manufacturer.name} - #{name}"
  end
end
