class StaffApplication < ApplicationRecord
  belongs_to :staff_role
  belongs_to :user
  belongs_to :reviewer, class_name: 'User', optional: true

  enum :status, {
    pending: 0,
    under_review: 1,
    approved: 2,
    rejected: 3,
    withdrawn: 4
  }

  scope :active, -> { where(deleted: [false, nil]) }
  scope :pending_applications, -> { where(status: [:pending, :under_review]) }

  validates :user_id, presence: true
  validates :staff_role_id, presence: true
  validates :user_id, uniqueness: { scope: :staff_role_id, message: 'has already applied for this role' }

  after_initialize :set_defaults

  private

  def set_defaults
    self.deleted ||= false
    self.status ||= :pending
    self.applied_at ||= Time.current
  end
end
