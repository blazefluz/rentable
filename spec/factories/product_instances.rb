FactoryBot.define do
  factory :product_instance do
    product { nil }
    serial_number { "MyString" }
    asset_tag { "MyString" }
    condition { 1 }
    status { 1 }
    purchase_date { "2026-02-25" }
    purchase_price_cents { 1 }
    purchase_price_currency { "MyString" }
    current_location { nil }
    notes { "MyText" }
    deleted { false }
  end
end
