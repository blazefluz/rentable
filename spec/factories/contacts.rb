FactoryBot.define do
  factory :contact do
    client { nil }
    first_name { "MyString" }
    last_name { "MyString" }
    title { "MyString" }
    email { "MyString" }
    phone { "MyString" }
    mobile { "MyString" }
    is_primary { false }
    decision_maker { false }
    receives_invoices { false }
    notes { "MyText" }
  end
end
