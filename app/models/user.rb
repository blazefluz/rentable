# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  # Associations
  belongs_to :instance, optional: true
  belongs_to :permission_group, optional: true
  has_many :managed_bookings, class_name: "Booking", foreign_key: :manager_id, dependent: :nullify
  has_many :booking_comments, dependent: :destroy
  has_many :user_positions, dependent: :destroy
  has_many :positions, through: :user_positions
  has_many :user_certifications, dependent: :destroy
  has_one :user_preference, dependent: :destroy
  has_many :asset_group_watchers, dependent: :destroy
  has_many :watched_asset_groups, through: :asset_group_watchers, source: :asset_group
  has_many :created_invitation_codes, class_name: 'InvitationCode', foreign_key: :created_by_id, dependent: :nullify
  has_many :comments, dependent: :destroy
  has_many :comment_upvotes, dependent: :destroy

  # Enums
  enum :role, {
    customer: 0,
    staff: 1,
    admin: 2
  }, prefix: true

  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  # Scopes
  scope :active, -> { where(suspended: [false, nil]) }
  scope :suspended, -> { where(suspended: true) }
  scope :verified, -> { where.not(email_verified_at: nil) }
  scope :unverified, -> { where(email_verified_at: nil) }

  # Callbacks
  before_create :generate_api_token
  before_create :generate_verification_token

  # Generate JWT token for authentication
  def generate_jwt
    payload = {
      user_id: id,
      email: email,
      role: role,
      exp: 24.hours.from_now.to_i
    }
    secret = Rails.application.credentials.secret_key_base || Rails.application.secret_key_base
    JWT.encode(payload, secret)
  end

  # Decode JWT token
  def self.from_jwt(token)
    secret = Rails.application.credentials.secret_key_base || Rails.application.secret_key_base
    decoded = JWT.decode(token, secret).first
    find_by(id: decoded['user_id'])
  rescue JWT::DecodeError, JWT::ExpiredSignature
    nil
  end

  # Password reset
  def generate_reset_password_token!
    self.reset_password_token = SecureRandom.urlsafe_base64
    self.reset_password_sent_at = Time.current
    save(validate: false)
  end

  def reset_password_token_valid?
    reset_password_sent_at.present? && reset_password_sent_at > 2.hours.ago
  end

  def reset_password!(new_password)
    self.password = new_password
    self.reset_password_token = nil
    self.reset_password_sent_at = nil
    save
  end

  # Email verification
  def verify_email!
    update(email_verified_at: Time.current, verification_token: nil)
  end

  def email_verified?
    email_verified_at.present?
  end

  # Suspension
  def suspend!(reason = nil)
    update(suspended: true, suspended_at: Time.current, suspended_reason: reason)
  end

  def unsuspend!
    update(suspended: false, suspended_at: nil, suspended_reason: nil)
  end

  def active?
    !suspended
  end

  # Social links
  def social_link(platform)
    return nil unless social_links.is_a?(Hash)
    social_links[platform.to_s]
  end

  def set_social_link(platform, url)
    self.social_links ||= {}
    self.social_links[platform.to_s] = url
  end

  # Permissions
  def has_permission?(permission_key)
    return false unless permission_group
    permission_group.has_permission?(permission_key)
  end

  # Preferences
  def preferences
    user_preference || create_user_preference
  end

  private

  def generate_api_token
    self.api_token = SecureRandom.hex(32)
  end

  def generate_verification_token
    self.verification_token = SecureRandom.urlsafe_base64(32)
  end
end
