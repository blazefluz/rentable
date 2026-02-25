# app/models/recurring_booking.rb
class RecurringBooking < ApplicationRecord
  include ActsAsTenant

  # Audit trail
  has_paper_trail

  # Associations
  has_many :bookings, dependent: :nullify
  belongs_to :client, optional: true
  belongs_to :created_by, class_name: "User"

  # Enums
  enum :frequency, {
    daily: 0,
    weekly: 1,
    biweekly: 2,
    monthly: 3,
    quarterly: 4,
    yearly: 5
  }, prefix: true

  # Validations
  validates :name, presence: true
  validates :frequency, presence: true
  validates :start_date, presence: true
  validates :next_occurrence, presence: true
  validates :interval, numericality: { greater_than: 0 }, allow_nil: true
  validate :end_date_after_start_date
  validate :valid_day_of_week
  validate :valid_day_of_month

  # Scopes
  scope :active, -> { where(active: true, deleted: false) }
  scope :due_for_generation, -> { active.where('next_occurrence <= ?', Time.current) }
  scope :not_deleted, -> { where(deleted: false) }

  # Calculate next occurrence based on frequency
  def calculate_next_occurrence(from_date = nil)
    base_date = from_date || next_occurrence || start_date

    case frequency
    when 'daily'
      base_date + interval.days
    when 'weekly'
      target_date = base_date + interval.weeks
      day_of_week.present? ? target_date.beginning_of_week + day_of_week.days : target_date
    when 'biweekly'
      base_date + (2 * interval).weeks
    when 'monthly'
      if day_of_month.present?
        next_month = base_date + interval.months
        Date.new(next_month.year, next_month.month, [day_of_month, next_month.end_of_month.day].min).to_datetime
      else
        base_date + interval.months
      end
    when 'quarterly'
      base_date + (3 * interval).months
    when 'yearly'
      base_date + interval.years
    else
      base_date + 1.week
    end
  end

  # Generate next booking instance
  def generate_next_booking!
    return false unless active?
    return false if deleted?
    return false if end_date.present? && next_occurrence > end_date
    return false if max_occurrences.present? && occurrence_count >= max_occurrences

    # Create booking from template
    booking_attrs = booking_template.symbolize_keys.merge(
      start_date: next_occurrence,
      end_date: next_occurrence + (booking_template['duration_days'] || 1).days,
      recurring_booking: self,
      status: 'pending'
    )

    booking = Booking.create!(booking_attrs)

    # Update recurring booking state
    update!(
      last_generated: Time.current,
      occurrence_count: occurrence_count + 1,
      next_occurrence: calculate_next_occurrence
    )

    booking
  end

  # Generate all due bookings (call this in a scheduled job)
  def self.generate_due_bookings!
    due_for_generation.find_each do |recurring_booking|
      begin
        recurring_booking.generate_next_booking!
      rescue => e
        Rails.logger.error("Failed to generate recurring booking #{recurring_booking.id}: #{e.message}")
      end
    end
  end

  # Preview upcoming bookings
  def preview_upcoming(count = 5)
    upcoming = []
    current_date = next_occurrence
    count.times do
      break if end_date.present? && current_date > end_date
      break if max_occurrences.present? && (occurrence_count + upcoming.size) >= max_occurrences

      upcoming << {
        occurrence_number: occurrence_count + upcoming.size + 1,
        start_date: current_date,
        end_date: current_date + (booking_template['duration_days'] || 1).days
      }

      current_date = calculate_next_occurrence(current_date)
    end
    upcoming
  end

  # Stop recurring bookings
  def stop!
    update!(active: false)
  end

  # Resume recurring bookings
  def resume!
    update!(active: true)
  end

  # Soft delete
  def soft_delete!
    update!(deleted: true, active: false)
  end

  # Check if series is complete
  def complete?
    return false unless max_occurrences.present?
    occurrence_count >= max_occurrences
  end

  # Check if series has ended
  def ended?
    return true if complete?
    return true if end_date.present? && Time.current > end_date
    false
  end

  # Get remaining occurrences
  def remaining_occurrences
    return nil unless max_occurrences.present?
    [max_occurrences - occurrence_count, 0].max
  end

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    errors.add(:end_date, "must be after start date") if end_date < start_date
  end

  def valid_day_of_week
    return if day_of_week.blank?
    errors.add(:day_of_week, "must be between 0 and 6") unless (0..6).include?(day_of_week)
  end

  def valid_day_of_month
    return if day_of_month.blank?
    errors.add(:day_of_month, "must be between 1 and 31") unless (1..31).include?(day_of_month)
  end
end
