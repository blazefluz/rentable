class Instance < ApplicationRecord
  belongs_to :owner, class_name: 'User', optional: true
  has_many :users, dependent: :nullify
  has_many :positions, dependent: :destroy
  has_many :permission_groups, dependent: :destroy
  has_many :user_positions, dependent: :destroy
  has_many :invitation_codes, dependent: :destroy

  validates :name, presence: true
  validates :subdomain, uniqueness: true, allow_blank: true

  scope :active, -> { where(active: true, deleted: [false, nil]) }

  after_initialize :set_defaults

  def setting(key)
    return nil unless settings.is_a?(Hash)
    settings[key.to_s]
  end

  def set_setting(key, value)
    self.settings ||= {}
    self.settings[key.to_s] = value
  end

  private

  def set_defaults
    self.active ||= true
    self.deleted ||= false
    self.settings ||= {}
  end
end
