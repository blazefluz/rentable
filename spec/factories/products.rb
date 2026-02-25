FactoryBot.define do
  factory :product do
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

    trait :with_location do
      association :location
    end

    trait :out_of_stock do
      quantity { 0 }
    end
  end
end
