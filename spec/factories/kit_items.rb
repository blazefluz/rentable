FactoryBot.define do
  factory :kit_item do
    association :kit
    association :product
    quantity { 1 }
  end
end
