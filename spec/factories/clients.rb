FactoryBot.define do
  factory :client do
    name { Faker::Company.name }
    email { Faker::Internet.email }
    phone { Faker::PhoneNumber.phone_number }
    website { Faker::Internet.url }
    address { Faker::Address.full_address }
    notes { Faker::Lorem.paragraph }
    archived { false }
    deleted { false }

    trait :archived do
      archived { true }
    end

    trait :deleted do
      deleted { true }
    end
  end
end
