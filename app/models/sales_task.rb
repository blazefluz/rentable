class SalesTask < ApplicationRecord
  include ActsAsTenant

  belongs_to :client
  belongs_to :user

  enum :task_type, {
    call: 0,
    email: 1,
    meeting: 2,
    proposal: 3,
    followup: 4,
    demo: 5,
    other: 6
  }

  enum :priority, {
    low: 0,
    medium: 1,
    high: 2,
    urgent: 3
  }

  enum :status, {
    pending: 0,
    in_progress: 1,
    completed: 2,
    cancelled: 3,
    overdue: 4
  }

  scope :active, -> { where(deleted: [false, nil]) }
  scope :pending_tasks, -> { where(status: [:pending, :in_progress]) }
  scope :overdue_tasks, -> { where('due_date < ? AND status IN (?)', Time.current, [statuses[:pending], statuses[:in_progress]]) }

  validates :title, presence: true
  validates :client_id, presence: true
  validates :user_id, presence: true

  after_initialize :set_defaults
  before_save :check_overdue

  def overdue?
    due_date.present? && due_date < Time.current && (pending? || in_progress?)
  end

  private

  def set_defaults
    self.deleted ||= false
    self.status ||= :pending
    self.priority ||= :medium
    self.task_type ||= :followup
  end

  def check_overdue
    self.status = :overdue if overdue?
  end
end
