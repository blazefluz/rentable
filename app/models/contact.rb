class Contact < ApplicationRecord
  belongs_to :client

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :phone, :mobile, format: { with: /\A[\d\s\-\+\(\)\.]+\z/ }, allow_blank: true

  # Scopes
  scope :primary, -> { where(is_primary: true) }
  scope :decision_makers, -> { where(decision_maker: true) }
  scope :invoice_recipients, -> { where(receives_invoices: true) }
  scope :active, -> { joins(:client).where(clients: { archived: false }) }

  # Callbacks
  before_save :ensure_single_primary, if: :is_primary?
  after_create :set_as_primary_if_first

  # Instance methods
  def full_name
    "#{first_name} #{last_name}".strip
  end

  def display_name
    title.present? ? "#{full_name}, #{title}" : full_name
  end

  def primary_phone
    mobile.presence || phone.presence
  end

  def contactable?
    email.present? || phone.present? || mobile.present?
  end

  private

  def ensure_single_primary
    return unless is_primary_changed? && is_primary?

    Contact.where(client_id: client_id, is_primary: true)
           .where.not(id: id)
           .update_all(is_primary: false)
  end

  def set_as_primary_if_first
    return if client.contacts.count > 1
    update_column(:is_primary, true)
  end
end
