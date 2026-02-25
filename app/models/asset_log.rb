class AssetLog < ApplicationRecord
  belongs_to :product
  belongs_to :user, optional: true

  enum :log_type, {
    created: 0,
    updated: 1,
    deleted: 2,
    archived: 3,
    unarchived: 4,
    transferred: 5,
    assigned: 6,
    returned: 7,
    maintenance_started: 8,
    maintenance_completed: 9,
    booked: 10,
    checked_out: 11,
    checked_in: 12,
    damaged: 13,
    repaired: 14,
    custom: 99
  }

  validates :product_id, presence: true
  validates :log_type, presence: true
  validates :description, presence: true

  scope :by_product, ->(product_id) { where(product_id: product_id) }
  scope :by_type, ->(log_type) { where(log_type: log_type) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :recent, -> { order(logged_at: :desc) }

  after_initialize :set_defaults

  private

  def set_defaults
    self.logged_at ||= Time.current
  end
end
