class Location < ApplicationRecord
  # Associations
  belongs_to :client, optional: true
  belongs_to :parent, class_name: "Location", optional: true
  has_many :children, class_name: "Location", foreign_key: :parent_id, dependent: :destroy

  # Products stored at this location
  has_many :stored_products, class_name: "Product", foreign_key: :storage_location_id, dependent: :nullify

  # Bookings for this venue
  has_many :venue_bookings, class_name: "Booking", foreign_key: :venue_location_id, dependent: :nullify

  # Validations
  validates :name, presence: true

  # Scopes
  scope :active, -> { where(archived: false, deleted: false) }
  scope :archived, -> { where(archived: true) }
  scope :root_locations, -> { where(parent_id: nil) }

  # Soft delete
  def soft_delete!
    update(deleted: true)
  end

  def archive!
    update(archived: true)
  end

  def unarchive!
    update(archived: false)
  end

  # Get full path (e.g., "Warehouse > Section A > Shelf 3")
  def full_path
    return name if parent.nil?
    "#{parent.full_path} > #{name}"
  end
end
