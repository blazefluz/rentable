FactoryBot.define do
  factory :company_setting do
    company { nil }
    setting_key { "MyString" }
    setting_value { "" }
    setting_type { 1 }
    description { "MyText" }
    default_value { "" }
    editable { false }
    category { "MyString" }
  end
end
