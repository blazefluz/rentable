FactoryBot.define do
  factory :recurring_booking do
    name { "MyString" }
    frequency { 1 }
    start_date { "2026-02-25 22:35:40" }
    end_date { "2026-02-25 22:35:40" }
    next_occurrence { "2026-02-25 22:35:40" }
    last_generated { "2026-02-25 22:35:40" }
    occurrence_count { 1 }
    max_occurrences { 1 }
    active { false }
    booking_template { "" }
    client { nil }
    created_by { nil }
  end
end
