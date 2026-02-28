FactoryBot.define do
  factory :company do
    sequence(:name) { |n| "Test Company #{n}" }
    sequence(:subdomain) { |n| "test-company-#{n}" }
    custom_domain { nil }
    logo { nil }
    primary_color { '#3B82F6' }
    secondary_color { '#10B981' }
    timezone { 'UTC' }
    default_currency { 'USD' }
    sequence(:business_email) { |n| "company#{n}@example.com" }
    business_phone { '+1-555-0123' }
    address { '123 Main St, Anytown, USA' }
    settings { {} }
    status { :active }
    subscription_tier { :professional }
    trial_ends_at { 14.days.from_now }
    subscription_started_at { Time.current }
    subscription_cancelled_at { nil }
    active { true }
    deleted { false }
    deleted_at { nil }

    trait :trial do
      status { :trial }
      subscription_tier { :free }
      trial_ends_at { 14.days.from_now }
      subscription_started_at { nil }
    end

    trait :starter do
      subscription_tier { :starter }
    end

    trait :professional do
      subscription_tier { :professional }
    end

    trait :enterprise do
      subscription_tier { :enterprise }
    end

    trait :suspended do
      status { :suspended }
      active { false }
    end

    trait :cancelled do
      status { :cancelled }
      subscription_cancelled_at { Time.current }
      active { false }
    end

    trait :deleted do
      deleted { true }
      deleted_at { Time.current }
      active { false }
    end
  end
end
