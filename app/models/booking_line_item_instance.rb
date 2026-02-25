class BookingLineItemInstance < ApplicationRecord
  include ActsAsTenant

  # Associations
  belongs_to :booking_line_item
  belongs_to :product_instance

  # Validations
  validates :booking_line_item_id, uniqueness: { scope: :product_instance_id }

  # Callbacks
  after_create :mark_instance_as_rented
  after_destroy :mark_instance_as_available

  private

  def mark_instance_as_rented
    product_instance.mark_as_rented
  end

  def mark_instance_as_available
    # Only mark available if no other active bookings
    return if product_instance.booking_line_item_instances.exists?
    product_instance.mark_as_available
  end
end
