# frozen_string_literal: true

FactoryBot.define do
  factory :email_sequence do
    association :email_campaign
    sequence_number { 1 }
    subject_template { "Follow up on {{quote_number}}" }
    body_template { "Hi {{customer_name}}, just following up on your quote." }
    send_delay_hours { 72 }
    active { true }

    trait :day_three do
      sequence_number { 1 }
      send_delay_hours { 72 }
    end

    trait :day_seven do
      sequence_number { 2 }
      send_delay_hours { 168 }
    end

    trait :inactive do
      active { false }
    end
  end
end
