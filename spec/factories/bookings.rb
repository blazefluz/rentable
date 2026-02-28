FactoryBot.define do
  factory :booking do
    association :company
    start_date { 3.days.from_now }
    end_date { 7.days.from_now }
    customer_name { Faker::Name.name }
    customer_email { Faker::Internet.email }
    customer_phone { Faker::PhoneNumber.phone_number }
    status { :confirmed }
    total_price_cents { 10000 }
    total_price_currency { 'USD' }
    archived { false }
    deleted { false }

    trait :pending do
      status { :pending }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :completed do
      status { :completed }
    end

    trait :draft do
      status { :draft }
    end

    trait :with_line_items do
      after(:create) do |booking|
        create(:booking_line_item, booking: booking, bookable: create(:product, company: booking.company))
      end
    end

    trait :with_client do
      association :client
    end
  end
end
