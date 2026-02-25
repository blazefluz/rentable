class MaintenanceJob < ApplicationRecord
  include ActsAsTenant

  belongs_to :product
  belongs_to :assigned_to, class_name: 'User', optional: true

  monetize :cost_cents, allow_nil: true, with_model_currency: :cost_currency

  enum :status, {
    pending: 0,
    in_progress: 1,
    completed: 2,
    cancelled: 3,
    on_hold: 4
  }

  enum :priority, {
    low: 0,
    medium: 1,
    high: 2,
    urgent: 3
  }

  scope :active, -> { where(deleted: [false, nil]) }
  scope :deleted, -> { where(deleted: true) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :overdue, -> { where('scheduled_date < ? AND status IN (?)', Time.current, [statuses[:pending], statuses[:in_progress]]) }

  validates :title, presence: true
  validates :status, presence: true
  validates :priority, presence: true

  after_initialize :set_defaults

  def overdue?
    scheduled_date.present? && scheduled_date < Time.current && (pending? || in_progress?)
  end

  private

  def set_defaults
    self.status ||= :pending
    self.priority ||= :medium
    self.deleted ||= false
    self.cost_currency ||= 'EUR'
  end
end
