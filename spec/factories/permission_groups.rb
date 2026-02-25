FactoryBot.define do
  factory :permission_group do
    name { "MyString" }
    permissions { "" }
    instance { nil }
    deleted { false }
  end
end
