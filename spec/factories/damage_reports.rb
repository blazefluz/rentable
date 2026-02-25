FactoryBot.define do
  factory :damage_report do
    booking { nil }
    product { nil }
    reported_by { nil }
    severity { 1 }
    description { "MyText" }
    repair_cost_cents { 1 }
    repair_cost_currency { "MyString" }
    resolved { false }
    resolved_at { "2026-02-25 20:39:45" }
    resolution_notes { "MyText" }
  end
end
