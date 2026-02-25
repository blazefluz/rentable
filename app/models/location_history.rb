class LocationHistory < ApplicationRecord
  include ActsAsTenant

  # Associations
  belongs_to :trackable, polymorphic: true
  belongs_to :location, class_name: "Location"
  belongs_to :previous_location, class_name: "Location", optional: true
  belongs_to :moved_by, class_name: "User", optional: true

  # Validations
  validates :trackable, presence: true
  validates :location, presence: true
  validates :moved_at, presence: true

  # Scopes
  scope :recent, -> { order(moved_at: :desc) }
  scope :for_trackable, ->(trackable) { where(trackable: trackable) }
  scope :for_location, ->(location_id) { where(location_id: location_id) }
  scope :between_dates, ->(start_date, end_date) { where(moved_at: start_date..end_date) }

  # Get location history for an item
  def self.track_movement(trackable, new_location, moved_by: nil, notes: nil)
    create!(
      trackable: trackable,
      location: new_location,
      previous_location: trackable.try(:current_location),
      moved_by: moved_by,
      moved_at: Time.current,
      notes: notes
    )
  end
end
