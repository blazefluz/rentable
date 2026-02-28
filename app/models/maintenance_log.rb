class MaintenanceLog < ApplicationRecord
  belongs_to :maintenance_schedule
  belongs_to :performed_by, class_name: 'User'

  validates :completed_at, presence: true
  validates :performed_by, presence: true

  scope :recent, -> { order(completed_at: :desc) }
  scope :for_schedule, ->(schedule_id) { where(maintenance_schedule_id: schedule_id) }
end
