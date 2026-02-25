FactoryBot.define do
  factory :asset_log do
    product { nil }
    user { nil }
    log_type { 1 }
    description { "MyText" }
    metadata { "" }
    logged_at { "2026-02-25 18:10:44" }
  end
end
