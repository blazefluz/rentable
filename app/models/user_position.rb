class UserPosition < ApplicationRecord
  belongs_to :user
  belongs_to :position
  belongs_to :instance

  validates :user_id, presence: true
  validates :position_id, presence: true

  scope :active, -> { where(active: true, deleted: [false, nil]) }
  scope :current, -> { where('(start_date IS NULL OR start_date <= ?) AND (end_date IS NULL OR end_date >= ?)', Time.current, Time.current) }
  scope :expired, -> { where('end_date < ?', Time.current) }

  after_initialize :set_defaults

  def current?
    (start_date.nil? || start_date <= Time.current) && (end_date.nil? || end_date >= Time.current)
  end

  def expired?
    end_date.present? && end_date < Time.current
  end

  private

  def set_defaults
    self.active ||= true
    self.deleted ||= false
  end
end
