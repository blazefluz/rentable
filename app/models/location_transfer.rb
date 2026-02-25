# app/models/location_transfer.rb
class LocationTransfer < ApplicationRecord
  include ActsAsTenant

  # Audit trail
  has_paper_trail

  # Associations
  belongs_to :from_location, class_name: "Location"
  belongs_to :to_location, class_name: "Location"
  belongs_to :initiated_by, class_name: "User", optional: true
  belongs_to :completed_by, class_name: "User", optional: true
  belongs_to :booking_line_item, optional: true
  belongs_to :booking, optional: true
  has_many :booking_line_items, dependent: :nullify

  # Enums
  enum :transfer_type, {
    internal: 0,           # Between company locations
    delivery: 1,           # To customer/venue
    pickup: 2,             # From customer/venue
    return: 3,             # Return to warehouse
    restock: 4,            # Restocking transfer
    maintenance_transfer: 5 # To/from maintenance
  }, prefix: true

  enum :status, {
    pending: 0,
    approved: 1,
    in_transit: 2,
    arrived: 3,
    completed: 4,
    cancelled: 5,
    failed: 6
  }, prefix: true

  # Validations
  validates :from_location, :to_location, presence: true
  validates :transfer_type, :status, presence: true
  validate :different_locations

  # Scopes
  scope :active, -> { where(deleted: false).where.not(status: [:cancelled, :completed]) }
  scope :in_progress, -> { where(status: [:approved, :in_transit]) }
  scope :completed_transfers, -> { where(status: :completed) }
  scope :pending_approval, -> { where(status: :pending) }
  scope :for_booking, ->(booking_id) { where(booking_id: booking_id) }
  scope :from_location, ->(location_id) { where(from_location_id: location_id) }
  scope :to_location, ->(location_id) { where(to_location_id: location_id) }

  # Initiate transfer
  def initiate!(user: nil)
    update!(
      status: :approved,
      initiated_at: Time.current,
      initiated_by: user
    )
  end

  # Mark as in transit
  def mark_in_transit!(user: nil)
    return false unless status_approved?

    update!(
      status: :in_transit,
      in_transit_at: Time.current
    )
  end

  # Mark as arrived
  def mark_arrived!
    return false unless status_in_transit?

    update!(status: :arrived)
  end

  # Complete transfer
  def complete!(user: nil)
    return false unless status_arrived? || status_in_transit?

    transaction do
      update!(
        status: :completed,
        completed_at: Time.current,
        completed_by: user
      )

      # Update line item status
      if booking_line_item
        booking_line_item.update!(transfer_status: :transfer_completed)
      end

      # Update all associated line items
      booking_line_items.each do |item|
        item.update!(transfer_status: :transfer_completed)
      end
    end
  end

  # Cancel transfer
  def cancel!(reason: nil)
    update!(
      status: :cancelled,
      notes: [notes, reason].compact.join("\n")
    )
  end

  # Check if late
  def late?
    return false unless expected_arrival_at.present?
    return false if status_completed?
    Time.current > expected_arrival_at
  end

  # Days until expected arrival
  def days_until_arrival
    return nil unless expected_arrival_at.present?
    return 0 if status_completed?
    ((expected_arrival_at - Time.current) / 1.day).ceil
  end

  # Duration in transit
  def transit_duration
    return nil unless in_transit_at.present?
    end_time = completed_at || Time.current
    ((end_time - in_transit_at) / 1.hour).round(1)
  end

  # Get transfer progress
  def progress_percentage
    case status
    when 'pending' then 0
    when 'approved' then 25
    when 'in_transit' then 50
    when 'arrived' then 75
    when 'completed' then 100
    else 0
    end
  end

  # Soft delete
  def soft_delete!
    update!(deleted: true)
  end

  private

  def different_locations
    if from_location_id == to_location_id
      errors.add(:base, "From and to locations must be different")
    end
  end
end
