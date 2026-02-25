FactoryBot.define do
  factory :location_transfer do
    from_location { nil }
    to_location { nil }
    initiated_by { nil }
    completed_by { nil }
    transfer_type { 1 }
    status { 1 }
    initiated_at { "2026-02-25 22:50:48" }
    completed_at { "2026-02-25 22:50:48" }
    notes { "MyText" }
  end
end
