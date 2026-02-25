# app/models/booking_line_item.rb
class BookingLineItem < ApplicationRecord
  belongs_to :booking
  belongs_to :bookable, polymorphic: true

  # Monetize
  monetize :price_cents, as: :price, with_model_currency: :price_currency

  # Validations
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :days, numericality: { greater_than: 0, only_integer: true }
  validates :price_currency, inclusion: { in: %w[NGN USD] }

  # Callbacks
  before_validation :set_price_from_bookable
  before_validation :set_days_from_booking

  # Calculate line total
  def line_total
    price * quantity * days
  end

  private

  def set_price_from_bookable
    return unless bookable
    self.price = bookable.daily_price
  end

  def set_days_from_booking
    return unless booking
    self.days = booking.rental_days
  end
end
