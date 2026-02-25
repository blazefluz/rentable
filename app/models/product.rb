# app/models/product.rb
class Product < ApplicationRecord
  include ActsAsTenant

  # Audit trail
  has_paper_trail

  # Associations
  has_many :kit_items, dependent: :destroy
  has_many :kits, through: :kit_items
  has_many :booking_line_items, as: :bookable
  has_many :bookings, through: :booking_line_items
  has_many :maintenance_jobs, dependent: :destroy
  has_many :asset_assignments, dependent: :destroy
  has_many :asset_logs, dependent: :destroy
  has_many :product_asset_flags, dependent: :destroy
  has_many :asset_flags, through: :product_asset_flags
  has_many :asset_group_products, dependent: :destroy
  has_many :asset_groups, through: :asset_group_products
  has_many_attached :images

  belongs_to :product_type, optional: true
  belongs_to :storage_location, class_name: "Location", optional: true

  # Monetize
  monetize :daily_price_cents, as: :daily_price, with_model_currency: :daily_price_currency
  monetize :weekly_price_cents, as: :weekly_price, with_model_currency: :weekly_price_currency
  monetize :value_cents, as: :value, currency: :daily_price_currency

  # Validations
  validates :name, presence: true
  validates :daily_price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :barcode, uniqueness: true, allow_blank: true
  validates :asset_tag, uniqueness: true, allow_blank: true
  validates :daily_price_currency, inclusion: { in: %w[USD EUR GBP] }
  validates :weekly_price_currency, inclusion: { in: %w[USD EUR GBP] }

  # Scopes
  scope :active, -> { where(active: true, archived: false, deleted: false) }
  scope :archived, -> { where(archived: true) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :search, ->(query) { where("name ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%") if query.present? }
  scope :by_product_type, ->(type_id) { where(product_type_id: type_id) if type_id.present? }
  scope :public_visible, -> { where(show_public: true) }

  # Check if product is available for given date range and quantity
  def available?(start_date, end_date, requested_qty = 1)
    AvailabilityChecker.new(self, start_date, end_date, requested_qty).available?
  end

  # Get available quantity for date range
  def available_quantity(start_date, end_date)
    AvailabilityChecker.new(self, start_date, end_date).available_quantity
  end
end
