# app/models/user.rb
class User < ApplicationRecord
  has_secure_password

  # Associations
  has_many :managed_bookings, class_name: "Booking", foreign_key: :manager_id, dependent: :nullify
  has_many :booking_comments, dependent: :destroy

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

  # Callbacks
  before_create :generate_api_token

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

  private

  def generate_api_token
    self.api_token = SecureRandom.hex(32)
  end
end
