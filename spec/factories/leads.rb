FactoryBot.define do
  factory :lead do
    name { "MyString" }
    email { "MyString" }
    phone { "MyString" }
    company { "MyString" }
    source { "MyString" }
    status { 1 }
    expected_value_cents { 1 }
    expected_value_currency { "MyString" }
    probability { 1 }
    expected_close_date { "2026-02-25" }
    assigned_to_id { "" }
    converted_to_client_id { "" }
    converted_at { "2026-02-25 23:53:14" }
    notes { "MyText" }
    lost_reason { "MyText" }
  end
end
