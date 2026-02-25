FactoryBot.define do
  factory :maintenance_job do
    product { nil }
    title { "MyString" }
    description { "MyText" }
    status { 1 }
    priority { 1 }
    scheduled_date { "2026-02-25 18:06:27" }
    completed_date { "2026-02-25 18:06:27" }
    assigned_to { nil }
    cost_cents { 1 }
    cost_currency { "MyString" }
    notes { "MyText" }
    deleted { false }
  end
end
