# frozen_string_literal: true

FactoryBot.define do
  factory :email_queue do
    association :company
    recipient { Faker::Internet.email }
    subject { "Test Email Subject" }
    body { "Test email body content" }
    status { :pending }
    attempts { 0 }
    metadata { {} }

    trait :sent do
      status { :sent }
      sent_at { Time.current }
    end

    trait :delivered do
      status { :sent }
      sent_at { 1.hour.ago }
      delivered_at { 50.minutes.ago }
    end

    trait :opened do
      status { :sent }
      sent_at { 2.hours.ago }
      delivered_at { 1.hour.ago }
      opened_at { 30.minutes.ago }
    end

    trait :clicked do
      status { :sent }
      sent_at { 3.hours.ago }
      delivered_at { 2.hours.ago }
      opened_at { 1.hour.ago }
      clicked_at { 30.minutes.ago }
    end

    trait :bounced do
      status { :failed }
      bounced_at { Time.current }
      bounce_reason { "Email address does not exist" }
    end

    trait :with_campaign do
      association :email_campaign
      association :email_sequence
    end
  end
end
