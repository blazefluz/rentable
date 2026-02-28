# app/models/maintenance_schedule.rb
class MaintenanceSchedule < ApplicationRecord
  include ActsAsTenant
  acts_as_tenant(:company)

  # Associations
  belongs_to :product
  belongs_to :company
  belongs_to :assigned_to, class_name: 'User', optional: true
  has_many :maintenance_logs, dependent: :destroy

  # Enums
  enum :frequency, {
    hours_based: 'hours_based',
    days_based: 'days_based',
    usage_based: 'usage_based'
  }, prefix: true

  enum :status, {
    scheduled: 'scheduled',
    in_progress: 'in_progress',
    completed: 'completed',
    overdue: 'overdue'
  }, prefix: true

  # Validations
  validates :name, presence: true
  validates :frequency, presence: true
  validates :interval_value, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :interval_unit, presence: true
  validates :interval_unit, inclusion: { in: %w[hours days rentals] }

  # Scopes
  scope :enabled, -> { where(enabled: true) }
  scope :due_soon, ->(days = 7) { enabled.where('next_due_date > ? AND next_due_date <= ?', Time.current, days.days.from_now).where.not(status: 'completed') }
  scope :overdue, -> { enabled.where('next_due_date < ?', Time.current).where.not(status: 'completed') }
  scope :for_product, ->(product_id) { where(product_id: product_id) }
  scope :assigned_to_user, ->(user_id) { where(assigned_to_id: user_id) }

  # Callbacks
  before_validation :set_initial_due_date, on: :create, if: -> { next_due_date.blank? }
  after_save :check_and_mark_overdue, if: -> { saved_change_to_next_due_date? || saved_change_to_status? }

  # Calculate next due date based on last completion
  def calculate_next_due_date
    base_time = last_completed_at || Time.current

    case frequency
    when 'hours_based'
      base_time + interval_value.hours
    when 'days_based'
      base_time + interval_value.days
    when 'usage_based'
      calculate_usage_based_due_date(base_time)
    end
  end

  # Mark as overdue if past due date
  def mark_overdue!
    return unless next_due_date.present? && next_due_date < Time.current
    return if status_completed?

    update(status: :overdue)
  end

  # Check if maintenance is due soon (within specified days)
  def due_soon?(days = 7)
    return false unless next_due_date.present?
    next_due_date <= days.days.from_now && next_due_date > Time.current
  end

  # Check if currently overdue
  def overdue?
    return false unless next_due_date.present?
    next_due_date < Time.current && !status_completed?
  end

  # Days until due (negative if overdue)
  def days_until_due
    return nil unless next_due_date.present?
    ((next_due_date - Time.current) / 1.day).round
  end

  # Complete this maintenance task
  def complete!(completed_by:, notes: nil)
    transaction do
      # Create maintenance log
      maintenance_logs.create!(
        performed_by: completed_by,
        completed_at: Time.current,
        notes: notes
      )

      # Update schedule
      update!(
        last_completed_at: Time.current,
        next_due_date: calculate_next_due_date,
        status: :scheduled
      )
    end
  end

  # Human-readable schedule description
  def schedule_description
    case frequency
    when 'hours_based'
      "Every #{interval_value} hour#{'s' if interval_value > 1}"
    when 'days_based'
      "Every #{interval_value} day#{'s' if interval_value > 1}"
    when 'usage_based'
      "Every #{interval_value} rental#{'s' if interval_value > 1}"
    end
  end

  private

  def set_initial_due_date
    self.next_due_date = calculate_next_due_date
  end

  def check_and_mark_overdue
    mark_overdue! if enabled? && next_due_date.present? && next_due_date < Time.current && !status_completed?
  end

  def calculate_usage_based_due_date(base_time)
    # For usage-based (e.g., every 50 rentals), estimate based on avg rental frequency
    return base_time + 30.days if product.bookings.count.zero?

    # Calculate average rentals per day
    days_since_product_created = [(Time.current - product.created_at) / 1.day, 1].max
    avg_rentals_per_day = product.bookings.count.to_f / days_since_product_created

    # Avoid division by zero
    return base_time + 30.days if avg_rentals_per_day.zero?

    # Calculate days until next maintenance
    days_until_due = (interval_value / avg_rentals_per_day).ceil
    base_time + days_until_due.days
  end
end
