class Client < ApplicationRecord
  include ActsAsTenant

  # Audit trail
  has_paper_trail

  # Associations
  has_many :bookings, dependent: :nullify
  has_many :locations, dependent: :destroy
  has_many :business_entities, dependent: :destroy
  has_many :addresses, as: :addressable, dependent: :destroy
  has_many :sales_tasks, dependent: :destroy
  has_many :notes, as: :notable, dependent: :destroy
  has_many_attached :attachments

  # Money
  monetize :account_value_cents, allow_nil: true, with_model_currency: :account_value_currency

  # Enums
  enum :priority, {
    low: 0,
    medium: 1,
    high: 2,
    vip: 3
  }

  # Validations
  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :email, uniqueness: { case_sensitive: false }, if: -> { email.present? }

  # Scopes
  scope :active, -> { where(archived: false, deleted: false) }
  scope :archived, -> { where(archived: true) }
  scope :search, ->(query) { where("name ILIKE ? OR email ILIKE ?", "%#{query}%", "%#{query}%") if query.present? }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :by_position, -> { order(position: :asc) }

  # Soft delete
  def soft_delete!
    update(deleted: true)
  end

  def archive!
    update(archived: true)
  end

  def unarchive!
    update(archived: false)
  end

  # Calculate total value from completed bookings
  def calculate_account_value
    total = bookings.where(status: [:confirmed, :completed]).sum(:total_price_cents)
    update(
      account_value_cents: total,
      account_value_currency: bookings.first&.total_price_currency || 'USD'
    )
  end

  after_initialize :set_defaults

  private

  def set_defaults
    self.priority ||= :medium
    self.account_value_currency ||= 'USD'
  end
end
