FactoryBot.define do
  factory :client_metric do
    client { nil }
    metric_date { "2026-02-25" }
    rentals_count { 1 }
    revenue_cents { 1 }
    revenue_currency { "MyString" }
    items_rented { 1 }
    utilization_rate { "9.99" }
    average_rental_duration { "9.99" }
  end
end
