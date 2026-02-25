FactoryBot.define do
  factory :staff_assignment do
    staff_role { nil }
    user { nil }
    booking { nil }
    start_date { "2026-02-25 18:19:05" }
    end_date { "2026-02-25 18:19:05" }
    status { 1 }
    notes { "MyText" }
    deleted { false }
  end
end
