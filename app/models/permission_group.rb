class PermissionGroup < ApplicationRecord
  belongs_to :instance
  has_many :users, dependent: :nullify

  validates :name, presence: true

  scope :active, -> { where(deleted: [false, nil]) }

  after_initialize :set_defaults

  def has_permission?(permission_key)
    return false unless permissions.is_a?(Hash)
    permissions[permission_key.to_s] == true
  end

  def grant_permission(permission_key)
    self.permissions ||= {}
    self.permissions[permission_key.to_s] = true
  end

  def revoke_permission(permission_key)
    self.permissions ||= {}
    self.permissions[permission_key.to_s] = false
  end

  private

  def set_defaults
    self.deleted ||= false
    self.permissions ||= {}
  end
end
