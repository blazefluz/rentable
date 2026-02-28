class MaintenanceJob < ApplicationRecord
  include ActsAsTenant

  belongs_to :product
  belongs_to :assigned_to, class_name: 'User', optional: true

  has_many_attached :before_photos
  has_many_attached :after_photos

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

  enum :maintenance_type, {
    routine: 0,
    inspection: 1,
    calibration: 2,
    cleaning: 3,
    lubrication: 4
  }, prefix: true

  enum :recurrence_pattern, {
    daily: 0,
    weekly: 1,
    monthly: 2,
    yearly: 3,
    custom: 4
  }, prefix: true

  scope :active, -> { where(deleted: [false, nil]) }
  scope :deleted, -> { where(deleted: true) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_priority, ->(priority) { where(priority: priority) }
  scope :overdue, -> { where('scheduled_date < ? AND status IN (?)', Time.current, [statuses[:pending], statuses[:in_progress]]) }
  scope :recurring, -> { where(is_recurring: true, auto_generate: true) }
  scope :due_for_generation, -> { recurring.where('next_occurrence_date <= ?', Date.today).where('last_generated_date IS NULL OR last_generated_date < next_occurrence_date') }

  validates :title, presence: true
  validates :status, presence: true
  validates :priority, presence: true
  validates :recurrence_pattern, presence: true, if: :is_recurring?
  validates :recurrence_interval, presence: true, numericality: { greater_than: 0 }, if: :is_recurring?

  after_initialize :set_defaults

  def overdue?
    scheduled_date.present? && scheduled_date < Time.current && (pending? || in_progress?)
  end

  # Mark job as complete with additional details
  def mark_complete!(params = {})
    update!(
      status: :completed,
      completed_at: Time.current,
      actual_duration_hours: params[:actual_duration_hours],
      findings: params[:findings],
      actions_taken: params[:actions_taken],
      parts_used: params[:parts_used],
      total_cost_breakdown: params[:total_cost_breakdown]
    )

    # Update product maintenance status
    product.update(maintenance_status: :current) if product.maintenance_status_in_maintenance?

    # Generate next occurrence if recurring
    generate_next_occurrence if is_recurring? && auto_generate?
  end

  # Generate the next occurrence of this recurring job
  def generate_next_occurrence
    return unless is_recurring?

    next_date = calculate_next_occurrence_date

    # Create a new maintenance job for the next occurrence
    self.class.create!(
      product: product,
      assigned_to: assigned_to,
      title: title,
      description: description,
      maintenance_type: maintenance_type,
      priority: priority,
      scheduled_date: next_date,
      is_recurring: true,
      recurrence_pattern: recurrence_pattern,
      recurrence_interval: recurrence_interval,
      day_of_week: day_of_week,
      day_of_month: day_of_month,
      auto_generate: auto_generate,
      estimated_duration_hours: estimated_duration_hours,
      required_parts: required_parts,
      procedure_notes: procedure_notes
    )

    # Update this job's tracking fields
    update!(
      last_generated_date: Date.today,
      next_occurrence_date: next_date
    )
  end

  # Calculate when the next occurrence should be scheduled
  def calculate_next_occurrence_date
    base_date = next_occurrence_date || scheduled_date || Date.today

    case recurrence_pattern
    when 'daily'
      base_date + recurrence_interval.days
    when 'weekly'
      next_date = base_date + recurrence_interval.weeks
      day_of_week.present? ? next_date.beginning_of_week + day_of_week.days : next_date
    when 'monthly'
      next_date = base_date + recurrence_interval.months
      day_of_month.present? ? Date.new(next_date.year, next_date.month, [day_of_month, next_date.end_of_month.day].min) : next_date
    when 'yearly'
      base_date + recurrence_interval.years
    when 'custom'
      # For custom patterns, default to interval days
      base_date + recurrence_interval.days
    else
      base_date + 1.month
    end
  end

  private

  def set_defaults
    self.status ||= :pending
    self.priority ||= :medium
    self.deleted ||= false
    self.cost_currency ||= 'EUR'
    self.is_recurring ||= false
    self.auto_generate ||= false
  end
end
