# app/models/kit.rb
class Kit < ApplicationRecord
  include ActsAsTenant

  # Tenant association
  belongs_to :company, optional: true

  # Associations
  has_many :kit_items, dependent: :destroy
  has_many :products, through: :kit_items
  has_many :booking_line_items, as: :bookable
  has_many :bookings, through: :booking_line_items
  has_many_attached :images

  # Nested attributes
  accepts_nested_attributes_for :kit_items, allow_destroy: true

  # Monetize
  monetize :daily_price_cents, as: :daily_price, with_model_currency: :daily_price_currency

  # Validations
  validates :name, presence: true
  validates :daily_price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :daily_price_currency, inclusion: { in: %w[USD EUR GBP] }

  # Scopes
  scope :active, -> { where(active: true) }

  # Check if all products in kit are available
  def available?(start_date, end_date, requested_qty = 1)
    return false if kit_items.empty?

    kit_items.all? do |kit_item|
      required_qty = kit_item.quantity * requested_qty
      kit_item.product.available?(start_date, end_date, required_qty)
    end
  end

  # Get maximum available quantity for this kit (limited by component with least availability)
  def available_quantity(start_date, end_date)
    return 0 if kit_items.empty?

    kit_items.map do |kit_item|
      product_available = kit_item.product.available_quantity(start_date, end_date)
      (product_available / kit_item.quantity.to_f).floor
    end.min
  end
end
