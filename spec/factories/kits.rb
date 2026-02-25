FactoryBot.define do
  factory :kit do
    name { "#{Faker::Commerce.product_name} Kit" }
    description { Faker::Lorem.paragraph }
    daily_price_cents { rand(5000..20000) }
    daily_price_currency { 'USD' }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_items do
      after(:create) do |kit|
        3.times do
          create(:kit_item, kit: kit, product: create(:product), quantity: 1)
        end
      end
    end
  end
end
