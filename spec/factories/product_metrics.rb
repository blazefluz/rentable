FactoryBot.define do
  factory :product_metric do
    product { nil }
    metric_date { "2026-02-25" }
    rental_days { 1 }
    idle_days { 1 }
    revenue_cents { 1 }
    revenue_currency { "MyString" }
    utilization_rate { "9.99" }
    times_rented { 1 }
  end
end
