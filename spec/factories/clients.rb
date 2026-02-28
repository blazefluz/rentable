FactoryBot.define do
  factory :client do
    association :company
    sequence(:name) { |n| "Client Company #{n}" }
    sequence(:email) { |n| "client#{n}@example.com" }
    phone { '+1-555-0100' }
    website { 'https://example.com' }
    address { '123 Main St, City, ST 12345' }
    archived { false }
    deleted { false }

    trait :archived do
      archived { true }
    end

    trait :deleted do
      deleted { true }
    end

    trait :with_notes do
      after(:create) do |client|
        create_list(:note, 2, notable: client)
      end
    end
  end
end
