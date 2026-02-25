class ProjectType < ApplicationRecord
  include ActsAsTenant

  # Associations
  has_many :bookings, dependent: :nullify

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :default_duration_days, numericality: { greater_than: 0, only_integer: true }, allow_nil: true

  # Scopes
  scope :active, -> { where(active: true, deleted: [false, nil]) }
  scope :deleted, -> { where(deleted: true) }

  # Feature flags helpers
  def feature_enabled?(feature_name)
    return false unless feature_flags.is_a?(Hash)
    feature_flags[feature_name.to_s] == true
  end

  def enable_feature(feature_name)
    self.feature_flags ||= {}
    self.feature_flags[feature_name.to_s] = true
  end

  def disable_feature(feature_name)
    self.feature_flags ||= {}
    self.feature_flags[feature_name.to_s] = false
  end

  # Settings helpers
  def get_setting(key)
    return nil unless settings.is_a?(Hash)
    settings[key.to_s]
  end

  def set_setting(key, value)
    self.settings ||= {}
    self.settings[key.to_s] = value
  end

  after_initialize :set_defaults

  private

  def set_defaults
    self.active ||= true
    self.deleted ||= false
    self.feature_flags ||= {}
    self.settings ||= {}
    self.requires_approval ||= false
    self.auto_confirm ||= false
  end
end
