class WaitlistEntry < ApplicationRecord
  # Associations
  belongs_to :bookable, polymorphic: true

  # Enums
  enum :status, {
    waiting: 0,
    notified: 1,
    fulfilled: 2,
    cancelled: 3,
    expired: 4
  }, prefix: true

  # Validations
  validates :customer_name, :customer_email, :start_date, :end_date, presence: true
  validates :customer_email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validate :end_date_after_start_date

  # Scopes
  scope :active, -> { where(status: [:waiting, :notified]) }
  scope :for_product, ->(product_id) { where(bookable_type: 'Product', bookable_id: product_id) }
  scope :for_kit, ->(kit_id) { where(bookable_type: 'Kit', bookable_id: kit_id) }
  scope :by_date_range, ->(start_date, end_date) {
    where('start_date <= ? AND end_date >= ?', end_date, start_date)
  }

  # Check if this waitlist entry can be fulfilled
  def can_be_fulfilled?
    return false unless status_waiting?
    bookable.available?(start_date, end_date, quantity)
  end

  # Mark as notified
  def notify!
    update(status: :notified, notified_at: Time.current)
  end

  # Mark as fulfilled
  def fulfill!
    update(status: :fulfilled)
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date <= start_date
      errors.add(:end_date, "must be after start date")
    end
  end
end
