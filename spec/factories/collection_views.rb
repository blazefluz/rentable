FactoryBot.define do
  factory :collection_view do
    product_collection { nil }
    user { nil }
    viewed_at { "2026-02-26 00:25:47" }
    ip_address { "MyString" }
    user_agent { "MyString" }
    referrer { "MyString" }
    session_id { "MyString" }
  end
end
