FactoryBot.define do
  factory :position do
    name { "MyString" }
    description { "MyText" }
    rank { 1 }
    instance { nil }
    deleted { false }
  end
end
