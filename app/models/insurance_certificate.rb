class InsuranceCertificate < ApplicationRecord
  include ActsAsTenant

  # Audit trail
  has_paper_trail

  # Associations
  belongs_to :product

  # Monetize
  monetize :coverage_amount_cents, as: :coverage_amount, with_model_currency: :coverage_amount_currency, allow_nil: true

  # Validations
  validates :policy_number, presence: true
  validates :provider, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  # Scopes
  scope :active, -> { where('end_date >= ? AND deleted = ?', Date.today, false) }
  scope :expired, -> { where('end_date < ? AND deleted = ?', Date.today, false) }
  scope :expiring_soon, ->(days = 30) { where('end_date BETWEEN ? AND ? AND deleted = ?', Date.today, Date.today + days.days, false) }

  def active?
    end_date >= Date.today && !deleted?
  end

  def expired?
    end_date < Date.today
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, 'must be after start date')
    end
  end
end
