# app/models/product.rb
class Product < ApplicationRecord
  # Associations
  has_many :kit_items, dependent: :destroy
  has_many :kits, through: :kit_items
  has_many :booking_line_items, as: :bookable
  has_many :bookings, through: :booking_line_items
  has_many_attached :images

  # Monetize
  monetize :daily_price_cents, as: :daily_price, with_model_currency: :daily_price_currency

  # Validations
  validates :name, presence: true
  validates :daily_price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :barcode, uniqueness: true, allow_blank: true
  validates :daily_price_currency, inclusion: { in: %w[NGN USD] }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :search, ->(query) { where("name ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%") if query.present? }

  # Check if product is available for given date range and quantity
  def available?(start_date, end_date, requested_qty = 1)
    AvailabilityChecker.new(self, start_date, end_date, requested_qty).available?
  end

  # Get available quantity for date range
  def available_quantity(start_date, end_date)
    AvailabilityChecker.new(self, start_date, end_date).available_quantity
  end
end
