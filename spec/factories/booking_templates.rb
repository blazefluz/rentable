FactoryBot.define do
  factory :booking_template do
    name { "MyString" }
    description { "MyText" }
    template_type { 1 }
    booking_data { "" }
    client { nil }
    created_by { nil }
    category { "MyString" }
    tags { "MyString" }
    is_public { false }
    favorite { false }
    usage_count { 1 }
    last_used_at { "2026-02-25 22:41:36" }
  end
end
