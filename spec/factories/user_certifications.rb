FactoryBot.define do
  factory :user_certification do
    user { nil }
    name { "MyString" }
    issued_date { "2026-02-25" }
    expiry_date { "2026-02-25" }
    certificate_number { "MyString" }
    deleted { false }
  end
end
