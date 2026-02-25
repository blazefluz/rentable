FactoryBot.define do
  factory :location_history do
    trackable { nil }
    location { nil }
    previous_location { nil }
    moved_by { nil }
    moved_at { "2026-02-25 20:59:00" }
    notes { "MyText" }
  end
end
