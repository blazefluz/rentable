class AssetGroupWatcher < ApplicationRecord
  belongs_to :user
  belongs_to :asset_group

  validates :user_id, uniqueness: { scope: :asset_group_id }

  scope :active, -> { where(deleted: [false, nil]) }
  scope :with_notifications, -> { where(notify_on_change: true) }

  after_initialize :set_defaults

  private

  def set_defaults
    self.notify_on_change ||= true
    self.deleted ||= false
  end
end
