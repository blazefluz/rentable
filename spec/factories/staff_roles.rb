FactoryBot.define do
  factory :staff_role do
    name { "MyString" }
    description { "MyText" }
    booking { nil }
    required_count { 1 }
    filled_count { 1 }
    status { 1 }
    deleted { false }
  end
end
