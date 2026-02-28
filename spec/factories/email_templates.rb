# frozen_string_literal: true

FactoryBot.define do
  factory :email_template do
    association :company
    name { "#{Faker::Marketing.buzzwords} Template" }
    category { :quote }
    subject { "Quote {{quote_number}} for {{customer_name}}" }
    html_body { "<p>Hi {{customer_name}},</p><p>Your quote is ready.</p>" }
    text_body { "Hi {{customer_name}}, Your quote is ready." }
    variable_schema do
      {
        customer_name: { type: 'string', required: true },
        quote_number: { type: 'string', required: true }
      }
    end
    active { true }

    trait :booking do
      category { :booking }
      name { "Booking Confirmation Template" }
      subject { "Booking {{booking_reference}} confirmed" }
    end

    trait :reminder do
      category { :reminder }
      name { "Booking Reminder Template" }
      subject { "Reminder: Your booking on {{start_date}}" }
    end

    trait :inactive do
      active { false }
    end
  end
end
