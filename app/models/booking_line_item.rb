# app/models/booking_line_item.rb
class BookingLineItem < ApplicationRecord
  belongs_to :booking
  belongs_to :bookable, polymorphic: true

  # Monetize
  monetize :price_cents, as: :price, with_model_currency: :price_currency

  # Enums for workflow status (matching AdamRMS 0-110 scale)
  enum :workflow_status, {
    none: 0,
    pending_pick: 10,
    picked: 20,
    prepping: 30,
    tested: 40,
    packed: 50,
    dispatched: 60,
    awaiting_checkin: 70,
    case_opened: 80,
    unpacked: 90,
    tested_return: 100,
    stored: 110
  }, prefix: true

  # Validations
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :days, numericality: { greater_than: 0, only_integer: true }
  validates :price_currency, inclusion: { in: %w[NGN USD] }
  validates :discount_percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  # Scopes
  scope :active, -> { where(deleted: false) }
  scope :by_status, ->(status) { where(workflow_status: status) if status.present? }

  # Callbacks
  before_validation :set_price_from_bookable
  before_validation :set_days_from_booking

  # Calculate line total (with discount applied)
  def line_total
    subtotal = price * quantity * days
    discount_amount = subtotal * (discount_percent / 100.0)
    subtotal - discount_amount
  end

  # Calculate line total without discount
  def line_subtotal
    price * quantity * days
  end

  # Soft delete
  def soft_delete!
    update(deleted: true)
  end

  # Workflow state transitions
  def advance_workflow!
    case workflow_status
    when "none" then workflow_status_pending_pick!
    when "pending_pick" then workflow_status_picked!
    when "picked" then workflow_status_prepping!
    when "prepping" then workflow_status_tested!
    when "tested" then workflow_status_packed!
    when "packed" then workflow_status_dispatched!
    when "dispatched" then workflow_status_awaiting_checkin!
    when "awaiting_checkin" then workflow_status_case_opened!
    when "case_opened" then workflow_status_unpacked!
    when "unpacked" then workflow_status_tested_return!
    when "tested_return" then workflow_status_stored!
    end
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
