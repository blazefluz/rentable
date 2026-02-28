# frozen_string_literal: true

FactoryBot.define do
  factory :email_campaign do
    association :company
    name { "#{Faker::Marketing.buzzwords} Campaign" }
    campaign_type { :marketing }
    status { :draft }
    active { true }
    delay_hours { 24 }
    trigger_conditions { { on_quote_sent: true } }

    trait :quote_followup do
      campaign_type { :quote_followup }
      name { "Quote Follow-up Campaign" }
    end

    trait :customer_reengagement do
      campaign_type { :customer_reengagement }
      name { "Customer Re-engagement Campaign" }
    end

    trait :active do
      status { :active }
      active { true }
    end

    trait :paused do
      status { :paused }
    end

    trait :with_sequences do
      after(:create) do |campaign|
        create_list(:email_sequence, 2, email_campaign: campaign)
      end
    end

    trait :scheduled do
      starts_at { 1.day.from_now }
      ends_at { 30.days.from_now }
    end
  end
end
