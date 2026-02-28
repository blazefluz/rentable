FactoryBot.define do
  factory :payment do
    association :booking
    amount_cents { 10000 }
    amount_currency { 'USD' }
    payment_type { :payment_received }
    payment_date { Date.today }
    payment_method { 'credit_card' }
    reference { Faker::Number.hexadecimal(digits: 10) }
    comment { nil }
    deleted { false }

    trait :sales_item do
      payment_type { :sales_item }
      amount_cents { 5000 }
    end

    trait :subhire do
      payment_type { :subhire }
      amount_cents { 2000 }
    end

    trait :staff_cost do
      payment_type { :staff_cost }
      amount_cents { 3000 }
    end

    trait :deleted do
      deleted { true }
    end
  end
end
