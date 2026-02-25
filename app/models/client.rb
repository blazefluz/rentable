class Client < ApplicationRecord
  # Audit trail
  has_paper_trail

  # Associations
  has_many :bookings, dependent: :nullify
  has_many :locations, dependent: :destroy
  has_many_attached :attachments

  # Validations
  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :email, uniqueness: { case_sensitive: false }, if: -> { email.present? }

  # Scopes
  scope :active, -> { where(archived: false, deleted: false) }
  scope :archived, -> { where(archived: true) }
  scope :search, ->(query) { where("name ILIKE ? OR email ILIKE ?", "%#{query}%", "%#{query}%") if query.present? }

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
end
