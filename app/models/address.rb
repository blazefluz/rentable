class Address < ApplicationRecord
  belongs_to :addressable, polymorphic: true

  enum :address_type, {
    billing: 0,
    shipping: 1,
    office: 2,
    warehouse: 3,
    other: 4
  }

  scope :active, -> { where(deleted: [false, nil]) }
  scope :primary, -> { where(is_primary: true) }

  validates :street_line1, presence: true
  validates :city, presence: true
  validates :country, presence: true

  after_initialize :set_defaults

  def full_address
    parts = [street_line1, street_line2, city, state, postal_code, country].compact
    parts.join(', ')
  end

  private

  def set_defaults
    self.deleted ||= false
    self.is_primary ||= false
    self.address_type ||= :billing
  end
end
