FactoryBot.define do
  factory :product_accessory do
    product { nil }
    accessory { nil }
    accessory_type { 1 }
    required { false }
    default_quantity { 1 }
  end
end
