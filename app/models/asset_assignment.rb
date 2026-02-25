class AssetAssignment < ApplicationRecord
  belongs_to :product
  belongs_to :assigned_to, polymorphic: true

  enum :status, {
    assigned: 0,
    in_use: 1,
    returned: 2,
    overdue: 3,
    lost: 4
  }

  scope :active, -> { where(deleted: [false, nil]) }
  scope :deleted, -> { where(deleted: true) }
  scope :current, -> { where(status: [:assigned, :in_use, :overdue]) }
  scope :overdue_assignments, -> { where('end_date < ? AND status IN (?)', Time.current, [statuses[:assigned], statuses[:in_use]]) }

  validates :product_id, presence: true
  validates :assigned_to, presence: true
  validates :start_date, presence: true
  validates :status, presence: true
  validate :end_date_after_start_date

  after_initialize :set_defaults

  def overdue?
    end_date.present? && end_date < Time.current && (assigned? || in_use?)
  end

  def duration_days
    return nil unless start_date && end_date
    ((end_date - start_date) / 1.day).round
  end

  def actual_duration_days
    return nil unless start_date
    end_time = returned_date || Time.current
    ((end_time - start_date) / 1.day).round
  end

  private

  def set_defaults
    self.status ||= :assigned
    self.deleted ||= false
    self.start_date ||= Time.current
  end

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?
    if end_date < start_date
      errors.add(:end_date, "must be after start date")
    end
  end
end
