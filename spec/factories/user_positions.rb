FactoryBot.define do
  factory :user_position do
    user { nil }
    position { nil }
    instance { nil }
    start_date { "2026-02-25 18:25:18" }
    end_date { "2026-02-25 18:25:18" }
    active { false }
    deleted { false }
  end
end
