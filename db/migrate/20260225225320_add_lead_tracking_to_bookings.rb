class AddLeadTrackingToBookings < ActiveRecord::Migration[8.1]
  def change
    add_column :bookings, :lead_source, :string
    add_column :bookings, :campaign_id, :string
    add_column :bookings, :referral_code, :string
    add_column :bookings, :lead_id, :bigint
    add_column :bookings, :utm_source, :string
    add_column :bookings, :utm_medium, :string
    add_column :bookings, :utm_campaign, :string
  end
end
