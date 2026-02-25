FactoryBot.define do
  factory :business_entity do
    name { "MyString" }
    legal_name { "MyString" }
    tax_id { "MyString" }
    entity_type { "MyString" }
    client { nil }
    active { false }
    notes { "MyText" }
    deleted { false }
  end
end
