class AddProjectTypeToBookings < ActiveRecord::Migration[8.1]
  def change
    add_reference :bookings, :project_type, foreign_key: true
  end
end
