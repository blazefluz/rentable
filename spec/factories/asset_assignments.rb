FactoryBot.define do
  factory :asset_assignment do
    product { nil }
    assigned_to { nil }
    start_date { "2026-02-25 18:07:35" }
    end_date { "2026-02-25 18:07:35" }
    purpose { "MyString" }
    notes { "MyText" }
    status { 1 }
    returned_date { "2026-02-25 18:07:35" }
    deleted { false }
  end
end
