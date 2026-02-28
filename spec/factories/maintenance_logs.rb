FactoryBot.define do
  factory :maintenance_log do
    association :maintenance_schedule
    association :performed_by, factory: :user
    completed_at { Time.current }
    notes { Faker::Lorem.paragraph }
  end
end
