FactoryBot.define do
  factory :booking_line_item do
    association :booking
    association :bookable, factory: :product
    quantity { 1 }
    price_cents { 5000 }
    price_currency { 'USD' }
    days { 4 }

    trait :with_kit do
      association :bookable, factory: :kit
    end
  end
end
