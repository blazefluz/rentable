class PaymentPlan < ApplicationRecord
  # Associations
  belongs_to :booking

  # Monetize
  monetize :total_amount_cents, as: :total_amount, with_model_currency: :total_amount_currency
  monetize :down_payment_cents, as: :down_payment, with_model_currency: :down_payment_currency, allow_nil: true
  monetize :installment_amount_cents, as: :installment_amount, with_model_currency: :installment_amount_currency

  # Enums
  enum :installment_frequency, {
    weekly: 0,
    biweekly: 1,
    monthly: 2,
    custom: 3
  }, prefix: true

  enum :status, {
    active: 0,
    completed: 1,
    defaulted: 2,
    cancelled: 3
  }, prefix: true

  # Validations
  validates :name, :total_amount_cents, :installment_amount_cents, presence: true
  validates :number_of_installments, numericality: { greater_than: 0 }
  validates :installments_paid, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :installments_paid_not_greater_than_total

  # Callbacks
  before_validation :set_defaults

  # Scopes
  scope :active_plans, -> { where(status: :active, active: true) }
  scope :overdue, -> { active_plans.where('next_payment_date < ?', Date.today) }

  # Instance Methods

  def remaining_installments
    number_of_installments - installments_paid.to_i
  end

  def remaining_balance
    total_amount - (installment_amount * installments_paid.to_i)
  end

  def next_payment_amount
    return Money.new(0, total_amount_currency) if status_completed?
    remaining_balance < installment_amount ? remaining_balance : installment_amount
  end

  def completion_percentage
    return 100.0 if number_of_installments.zero?
    (installments_paid.to_f / number_of_installments * 100).round(2)
  end

  def payment_overdue?
    return false if status_completed? || !active?
    next_payment_date.present? && next_payment_date < Date.today
  end

  def days_overdue
    return 0 unless payment_overdue?
    (Date.today - next_payment_date).to_i
  end

  # Record a payment
  def record_payment!(amount:, payment_date: Date.today, payment_method: nil, notes: nil)
    transaction do
      # Create payment record on booking
      booking.payments.create!(
        amount: amount,
        payment_type: :payment_received,
        payment_date: payment_date,
        payment_method: payment_method
      )

      # Update installments paid
      self.installments_paid += 1

      # Calculate next payment date
      self.next_payment_date = calculate_next_payment_date

      # Add note to payment plan notes
      if notes.present?
        self.notes = "#{self.notes}\n[#{Time.current}] Payment #{installments_paid}: #{notes}"
      end

      # Check if completed
      if installments_paid >= number_of_installments
        self.status = :completed
        booking.update!(collection_status: :current_status) if booking.fully_paid?
      end

      save!
    end
  end

  # Mark as defaulted
  def mark_defaulted!(reason: nil)
    update!(
      status: :defaulted,
      notes: "#{notes}\n\n[#{Time.current}] Defaulted: #{reason}"
    )
    booking.update!(collection_status: :in_collections)
  end

  # Cancel plan
  def cancel!(reason: nil)
    update!(
      status: :cancelled,
      active: false,
      notes: "#{notes}\n\n[#{Time.current}] Cancelled: #{reason}"
    )
  end

  # Reactivate plan
  def reactivate!
    update!(
      status: :active,
      active: true
    )
  end

  private

  def set_defaults
    self.installments_paid ||= 0
    self.active = true if active.nil?

    # Auto-calculate installment amount if not provided
    if installment_amount_cents.blank? && total_amount_cents.present? && number_of_installments.present?
      amount_after_down = total_amount_cents - down_payment_cents.to_i
      self.installment_amount_cents = (amount_after_down.to_f / number_of_installments).ceil
      self.installment_amount_currency = total_amount_currency
    end
  end

  def calculate_next_payment_date
    return nil if installments_paid >= number_of_installments

    case installment_frequency
    when 'weekly'
      next_payment_date.present? ? next_payment_date + 1.week : start_date + 1.week
    when 'biweekly'
      next_payment_date.present? ? next_payment_date + 2.weeks : start_date + 2.weeks
    when 'monthly'
      next_payment_date.present? ? next_payment_date + 1.month : start_date + 1.month
    else
      next_payment_date # Custom frequency - manual update
    end
  end

  def installments_paid_not_greater_than_total
    return unless installments_paid.present? && number_of_installments.present?

    if installments_paid > number_of_installments
      errors.add(:installments_paid, "cannot be greater than number_of_installments")
    end
  end
end
