FactoryBot.define do
  factory :pricing_rule do
    product { nil }
    product_type { nil }
    rule_type { 1 }
    name { "MyString" }
    start_date { "2026-02-25" }
    end_date { "2026-02-25" }
    day_of_week { 1 }
    min_days { 1 }
    max_days { 1 }
    discount_percentage { "9.99" }
    price_override_cents { 1 }
    price_override_currency { "MyString" }
    active { false }
    priority { 1 }
    deleted { false }
  end
end
