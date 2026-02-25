FactoryBot.define do
  factory :location do
    name { Faker::Address.city }
    address { Faker::Address.full_address }
    notes { Faker::Lorem.sentence }
    deleted { false }
    archived { false }

    trait :with_client do
      association :client
    end

    trait :archived do
      archived { true }
    end

    trait :deleted do
      deleted { true }
    end

    trait :with_parent do
      association :parent, factory: :location
    end
  end
end
