FactoryBot.define do
  factory :staff_application do
    staff_role { nil }
    user { nil }
    status { 1 }
    notes { "MyText" }
    applied_at { "2026-02-25 18:19:03" }
    reviewed_at { "2026-02-25 18:19:03" }
    reviewer { nil }
    deleted { false }
  end
end
