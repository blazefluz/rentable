class StaffRole < ApplicationRecord
  include ActsAsTenant

  belongs_to :booking
  has_many :staff_applications, dependent: :destroy
  has_many :staff_assignments, dependent: :destroy
  has_many :assigned_users, through: :staff_assignments, source: :user

  enum :status, {
    vacant: 0,
    partially_filled: 1,
    filled: 2,
    closed: 3
  }

  scope :active, -> { where(deleted: [false, nil]) }
  scope :vacant_roles, -> { where(status: [:vacant, :partially_filled]) }

  validates :name, presence: true
  validates :required_count, numericality: { greater_than: 0, only_integer: true }

  after_initialize :set_defaults
  before_save :update_status

  def vacancy_count
    required_count - filled_count
  end

  def has_vacancies?
    filled_count < required_count
  end

  private

  def set_defaults
    self.deleted ||= false
    self.required_count ||= 1
    self.filled_count ||= 0
    self.status ||= :vacant
  end

  def update_status
    if filled_count >= required_count
      self.status = :filled
    elsif filled_count > 0
      self.status = :partially_filled
    else
      self.status = :vacant
    end
  end
end
