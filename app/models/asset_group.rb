class AssetGroup < ApplicationRecord
  include ActsAsTenant

  has_many :asset_group_products, dependent: :destroy
  has_many :products, through: :asset_group_products
  has_many :asset_group_watchers, dependent: :destroy
  has_many :watchers, through: :asset_group_watchers, source: :user

  scope :active, -> { where(deleted: [false, nil]) }
  scope :deleted, -> { where(deleted: true) }

  validates :name, presence: true, uniqueness: true

  after_initialize :set_defaults
  after_update :notify_watchers, if: :saved_change_to_important_attributes?

  def add_watcher(user, notify_on_change: true)
    watchers << user unless watchers.include?(user)
    watcher = asset_group_watchers.find_by(user: user)
    watcher&.update(notify_on_change: notify_on_change)
  end

  def remove_watcher(user)
    watchers.delete(user)
  end

  private

  def set_defaults
    self.deleted ||= false
  end

  def saved_change_to_important_attributes?
    saved_change_to_name? || saved_change_to_description?
  end

  def notify_watchers
    asset_group_watchers.with_notifications.each do |watcher|
      # Here you would trigger notification to watcher.user
      # e.g., AssetGroupNotificationJob.perform_later(watcher.user_id, self.id)
    end
  end
end
