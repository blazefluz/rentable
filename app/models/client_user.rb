class ClientUser < ApplicationRecord
  belongs_to :client
  belongs_to :contact

  # Secure password
  has_secure_password validations: false

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :confirmed, -> { where.not(confirmed_at: nil) }
  scope :unconfirmed, -> { where(confirmed_at: nil) }
  scope :recently_signed_in, -> { where('last_sign_in_at > ?', 30.days.ago) }

  # Callbacks
  before_create :generate_confirmation_token
  before_save :sync_email_from_contact, if: -> { contact_id_changed? && email.blank? }

  # Instance methods
  def confirm!
    update!(confirmed_at: Time.current, confirmation_token: nil)
  end

  def confirmed?
    confirmed_at.present?
  end

  def send_confirmation_email
    generate_confirmation_token unless confirmation_token
    save!
    # TODO: Implement email sending via ActionMailer
    # ClientUserMailer.confirmation_email(self).deliver_later
  end

  def send_password_reset
    self.password_reset_token = SecureRandom.urlsafe_base64
    self.password_reset_sent_at = Time.current
    save!
    # TODO: Implement email sending
    # ClientUserMailer.password_reset_email(self).deliver_later
  end

  def password_reset_expired?
    return true unless password_reset_sent_at
    password_reset_sent_at < 2.hours.ago
  end

  def reset_password!(new_password)
    self.password = new_password
    self.password_reset_token = nil
    self.password_reset_sent_at = nil
    save!
  end

  def record_sign_in!(ip_address)
    self.sign_in_count = (sign_in_count || 0) + 1
    self.last_sign_in_at = current_sign_in_at || Time.current
    self.last_sign_in_ip = current_sign_in_ip
    self.current_sign_in_at = Time.current
    self.current_sign_in_ip = ip_address
    save!
  end

  def deactivate!
    update!(active: false)
  end

  def activate!
    update!(active: true)
  end

  def full_name
    contact&.full_name || email
  end

  private

  def generate_confirmation_token
    self.confirmation_token = SecureRandom.urlsafe_base64
    self.confirmation_sent_at = Time.current
  end

  def sync_email_from_contact
    self.email = contact.email if contact&.email.present?
  end
end
