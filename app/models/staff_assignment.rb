class StaffAssignment < ApplicationRecord
  belongs_to :staff_role
  belongs_to :user
  belongs_to :booking

  enum :status, {
    assigned: 0,
    confirmed: 1,
    in_progress: 2,
    completed: 3,
    cancelled: 4
  }

  scope :active, -> { where(deleted: [false, nil]) }
  scope :current_assignments, -> { where(status: [:assigned, :confirmed, :in_progress]) }

  validates :user_id, presence: true
  validates :staff_role_id, presence: true
  validates :booking_id, presence: true

  after_initialize :set_defaults
  after_create :update_staff_role_filled_count
  after_destroy :update_staff_role_filled_count

  private

  def set_defaults
    self.deleted ||= false
    self.status ||= :assigned
  end

  def update_staff_role_filled_count
    staff_role.update(filled_count: staff_role.staff_assignments.active.count)
  end
end
