class AddRecurringBookingToBookings < ActiveRecord::Migration[8.1]
  def change
    add_reference :bookings, :recurring_booking, null: true, foreign_key: true, index: true
  end
end
