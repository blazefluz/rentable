FactoryBot.define do
  factory :product_bundle_item do
    product_bundle { nil }
    product { nil }
    quantity { 1 }
    required { false }
    position { 1 }
  end
end
