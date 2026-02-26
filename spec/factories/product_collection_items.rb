FactoryBot.define do
  factory :product_collection_item do
    product_collection { nil }
    product { nil }
    position { 1 }
    featured { false }
    notes { "MyText" }
  end
end
