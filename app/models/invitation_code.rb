class InvitationCode < ApplicationRecord
  belongs_to :instance
  belongs_to :created_by, class_name: 'User'

  validates :code, presence: true, uniqueness: true

  scope :active, -> { where(deleted: [false, nil]).where('expires_at IS NULL OR expires_at > ?', Time.current) }
  scope :available, -> { active.where('max_uses IS NULL OR current_uses < max_uses') }

  before_validation :generate_code, on: :create
  after_initialize :set_defaults

  def valid_for_use?
    return false if deleted
    return false if expires_at && expires_at < Time.current
    return false if max_uses && current_uses >= max_uses
    true
  end

  def use!
    return false unless valid_for_use?
    increment!(:current_uses)
  end

  private

  def generate_code
    self.code ||= SecureRandom.alphanumeric(8).upcase
  end

  def set_defaults
    self.current_uses ||= 0
    self.deleted ||= false
  end
end
