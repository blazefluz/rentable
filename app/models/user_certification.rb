class UserCertification < ApplicationRecord
  belongs_to :user

  validates :name, presence: true

  scope :active, -> { where(deleted: [false, nil]) }
  scope :valid, -> { active.where('expiry_date IS NULL OR expiry_date >= ?', Date.current) }
  scope :expired, -> { active.where('expiry_date < ?', Date.current) }

  after_initialize :set_defaults

  def expired?
    expiry_date.present? && expiry_date < Date.current
  end

  def days_until_expiry
    return nil unless expiry_date
    (expiry_date - Date.current).to_i
  end

  private

  def set_defaults
    self.deleted ||= false
  end
end
