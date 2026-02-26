class ServiceAgreement < ApplicationRecord
  belongs_to :client

  # Money fields
  monetize :minimum_commitment_cents, allow_nil: true

  # Enums
  enum :agreement_type, {
    standard: 0,
    enterprise: 1,
    volume_discount: 2,
    preferred_partner: 3,
    trial: 4
  }

  enum :renewal_type, {
    manual: 0,
    automatic: 1,
    notification_only: 2
  }

  enum :payment_schedule, {
    monthly: 0,
    quarterly: 1,
    semi_annual: 2,
    annual: 3,
    upfront: 4
  }

  # Validations
  validates :name, presence: true
  validates :agreement_type, presence: true
  validates :start_date, presence: true
  validate :end_date_after_start_date

  # Scopes
  scope :active, -> { where(active: true) }
  scope :expired, -> { where('end_date < ?', Date.today) }
  scope :expiring_soon, -> { where('end_date BETWEEN ? AND ?', Date.today, 30.days.from_now.to_date) }
  scope :by_type, ->(type) { where(agreement_type: type) }
  scope :auto_renewing, -> { where(auto_renew: true) }

  # Callbacks
  before_save :check_expiration

  # Instance methods
  def active?
    return false unless active
    return false if expired?
    return false if start_date && start_date > Date.today
    true
  end

  def expired?
    end_date.present? && end_date < Date.today
  end

  def expiring_soon?
    return false unless end_date
    end_date.between?(Date.today, 30.days.from_now.to_date)
  end

  def days_until_expiry
    return nil unless end_date
    (end_date - Date.today).to_i
  end

  def days_remaining
    return Float::INFINITY unless end_date
    [days_until_expiry, 0].max
  end

  def duration_days
    return nil unless start_date && end_date
    (end_date - start_date).to_i
  end

  def renew!(new_end_date:, notes: nil)
    update!(
      end_date: new_end_date,
      notes: notes ? "#{self.notes}\n\nRenewed on #{Date.today}: #{notes}" : self.notes
    )
  end

  def terminate!(reason: nil)
    update!(
      active: false,
      end_date: Date.today,
      notes: notes ? "#{self.notes}\n\nTerminated on #{Date.today}: #{reason}" : "Terminated: #{reason}"
    )
  end

  def client_meeting_commitment?
    return true unless minimum_commitment_cents

    client_bookings = client.bookings.where(
      'start_date >= ? AND end_date <= ?',
      start_date,
      end_date || Date.today
    )

    total_spent = client_bookings.sum(:total_price_cents)
    total_spent >= minimum_commitment_cents
  end

  def commitment_progress
    return 100 unless minimum_commitment_cents

    client_bookings = client.bookings.where(
      'start_date >= ? AND end_date <= ?',
      start_date,
      end_date || Date.today
    )

    total_spent = client_bookings.sum(:total_price_cents)
    ((total_spent.to_f / minimum_commitment_cents) * 100).round(2)
  end

  private

  def end_date_after_start_date
    return unless end_date && start_date
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end

  def check_expiration
    self.active = false if expired? && active
  end
end
