# app/models/booking.rb
class Booking < ApplicationRecord
  # Associations
  has_many :booking_line_items, dependent: :destroy
  has_many :products, through: :booking_line_items, source: :bookable, source_type: "Product"
  has_many :kits, through: :booking_line_items, source: :bookable, source_type: "Kit"

  # Monetize
  monetize :total_price_cents, as: :total_price, with_model_currency: :total_price_currency

  # Enums
  enum :status, {
    draft: 0,
    pending: 1,
    confirmed: 2,
    paid: 3,
    cancelled: 4,
    completed: 5
  }, prefix: true

  # Validations
  validates :start_date, :end_date, :customer_name, :customer_email, presence: true
  validates :customer_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :total_price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :total_price_currency, inclusion: { in: %w[NGN USD] }
  validate :end_date_after_start_date
  validate :availability_on_create, on: :create

  # Callbacks
  before_validation :generate_reference_number, on: :create
  before_validation :calculate_total_price

  # Scopes
  scope :active, -> { where.not(status: [:cancelled]) }
  scope :confirmed_or_paid, -> { where(status: [:confirmed, :paid, :completed]) }
  scope :overlapping, ->(start_date, end_date) {
    where("start_date < ? AND end_date > ?", end_date, start_date)
  }

  # Calculate number of rental days
  def rental_days
    return 0 if start_date.nil? || end_date.nil?
    ((end_date.to_date - start_date.to_date).to_i + 1).clamp(1..)
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date <= start_date
      errors.add(:end_date, "must be after start date")
    end
  end

  def generate_reference_number
    self.reference_number ||= "BK#{Time.current.strftime('%Y%m%d')}#{SecureRandom.hex(4).upcase}"
  end

  def calculate_total_price
    return unless booking_line_items.any?

    days = rental_days
    currency = booking_line_items.first&.price_currency || "NGN"

    total_cents = booking_line_items.sum do |item|
      item.price_cents * item.quantity * days
    end

    self.total_price = Money.new(total_cents, currency)
  end

  def availability_on_create
    return if status_cancelled? || status_draft?

    booking_line_items.each do |line_item|
      bookable = line_item.bookable
      next unless bookable

      unless bookable.available?(start_date, end_date, line_item.quantity)
        errors.add(:base, "#{bookable.name} is not available for the selected dates")
      end
    end
  end
end
