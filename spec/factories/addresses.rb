FactoryBot.define do
  factory :address do
    addressable { nil }
    address_type { 1 }
    street_line1 { "MyString" }
    street_line2 { "MyString" }
    city { "MyString" }
    state { "MyString" }
    postal_code { "MyString" }
    country { "MyString" }
    is_primary { false }
    deleted { false }
  end
end
