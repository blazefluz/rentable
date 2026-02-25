class ProductType < ApplicationRecord
  include ActsAsTenant

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
  validates :color, format: { with: /\A#(?:[0-9a-fA-F]{3}){1,2}\z/, message: "must be a valid hex color" }, allow_blank: true
  validates :discount_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_blank: true

  # Scopes
  scope :active, -> { where(archived: [false, nil]) }
  scope :archived, -> { where(archived: true) }
  scope :by_category, ->(category) { where(category: category) if category.present? }
  scope :search, ->(query) { where("name ILIKE ? OR category ILIKE ?", "%#{query}%", "%#{query}%") if query.present? }

  # Get full name with manufacturer (e.g., "Canon - EOS R5")
  def full_name
    "#{manufacturer.name} - #{name}"
  end

  # Calculate discounted price
  def discounted_daily_price
    return daily_price unless discount_percentage.present? && discount_percentage > 0
    daily_price * (1 - discount_percentage / 100)
  end

  def discounted_weekly_price
    return weekly_price unless discount_percentage.present? && discount_percentage > 0
    weekly_price * (1 - discount_percentage / 100)
  end

  after_initialize :set_defaults

  private

  def set_defaults
    self.archived ||= false
    self.color ||= '#6366f1' # Default indigo
  end
end
