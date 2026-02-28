# frozen_string_literal: true

FactoryBot.define do
  factory :client_segment do
    association :company
    name { "#{Faker::Commerce.department} Clients" }
    description { Faker::Lorem.sentence }
    filter_rules { { lifetime_value: 'high' } }
    auto_update { true }
    active { true }

    trait :high_value do
      name { "High Value Clients" }
      filter_rules { { lifetime_value: 'high' } }
    end

    trait :dormant do
      name { "Dormant Clients" }
      filter_rules { { last_booking_date: 'dormant' } }
    end

    trait :static do
      auto_update { false }
    end

    trait :inactive do
      active { false }
    end
  end
end
