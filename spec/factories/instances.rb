FactoryBot.define do
  factory :instance do
    name { "MyString" }
    subdomain { "MyString" }
    settings { "" }
    active { false }
    owner { nil }
    deleted { false }
  end
end
