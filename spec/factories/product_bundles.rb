FactoryBot.define do
  factory :product_bundle do
    name { "MyString" }
    description { "MyText" }
    bundle_type { 1 }
    enforce_bundling { false }
    discount_percentage { "9.99" }
    active { false }
    deleted { false }
  end
end
