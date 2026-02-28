FactoryBot.define do
  factory :user do
    association :company
    email { Faker::Internet.email }
    password { 'password123' }
    password_confirmation { 'password123' }
    name { Faker::Name.name }
    role { :staff }
    suspended { false }
    email_verified_at { Time.current }

    trait :admin do
      role { :admin }
    end

    trait :customer do
      role { :customer }
    end

    trait :suspended do
      suspended { true }
      suspended_at { Time.current }
    end

    trait :unverified do
      email_verified_at { nil }
    end
  end
end
