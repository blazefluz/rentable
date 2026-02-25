class Payment < ApplicationRecord
  # Audit trail
  has_paper_trail

  # Associations
  belongs_to :booking

  # Monetize
  monetize :amount_cents, as: :amount, with_model_currency: :amount_currency

  # Enums (matching AdamRMS payment types)
  enum :payment_type, {
    payment_received: 1,    # Customer payment received
    sales_item: 2,          # Non-rental sales item (cables, batteries, etc)
    subhire: 3,             # External rental cost (renting from another company)
    staff_cost: 4           # Staff labor cost
  }, prefix: true

  # Validations
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :payment_type, presence: true
  validates :amount_currency, inclusion: { in: %w[USD EUR GBP] }

  # Scopes
  scope :active, -> { where(deleted: false) }
  scope :by_type, ->(type) { where(payment_type: type) if type.present? }
  scope :by_date_range, ->(start_date, end_date) {
    where(payment_date: start_date..end_date) if start_date.present? && end_date.present?
  }

  # Soft delete
  def soft_delete!
    update(deleted: true)
  end
end
