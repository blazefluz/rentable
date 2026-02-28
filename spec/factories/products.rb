FactoryBot.define do
  factory :product do
    association :company
    name { Faker::Commerce.product_name }
    description { Faker::Lorem.paragraph }
    daily_price_cents { rand(1000..10000) }
    daily_price_currency { 'USD' }
    quantity { rand(1..10) }
    category { %w[Camera Lens Lighting Audio Grip].sample }
    barcode { Faker::Barcode.ean }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_weekly_price do
      weekly_price_cents { daily_price_cents * 5 }
      weekly_price_currency { 'USD' }
    end

    trait :with_weekend_price do
      weekend_price_cents { daily_price_cents * 1.5 }
      weekend_price_currency { 'USD' }
    end

    trait :with_location do
      association :location
    end

    trait :out_of_stock do
      quantity { 0 }
    end
  end
end
