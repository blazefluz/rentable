class AddLifecycleFieldsToClients < ActiveRecord::Migration[8.1]
  def change
    add_column :clients, :first_rental_date, :date
    add_column :clients, :last_rental_date, :date
    add_column :clients, :lifetime_value_cents, :integer
    add_column :clients, :lifetime_value_currency, :string
    add_column :clients, :total_rentals, :integer
    add_column :clients, :average_booking_value_cents, :integer
    add_column :clients, :average_booking_value_currency, :string
    add_column :clients, :health_score, :integer
    add_column :clients, :churn_risk, :integer
    add_column :clients, :last_activity_at, :datetime
  end
end
