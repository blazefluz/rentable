FactoryBot.define do
  factory :expense do
    association :company

    category { :maintenance }
    amount_cents { 10000 }
    amount_currency { 'USD' }
    date { Date.current }
    vendor { Faker::Company.name }
    invoice_number { "INV-#{Faker::Number.number(digits: 6)}" }
    description { Faker::Lorem.sentence }
    notes { Faker::Lorem.paragraph }
    payment_method { 'credit_card' }
    payment_date { nil }

    trait :paid do
      payment_date { date + 7.days }
    end

    trait :unpaid do
      payment_date { nil }
    end

    trait :overdue do
      date { Date.current - 30.days }
      payment_date { nil }
    end
  end
end
