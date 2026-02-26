FactoryBot.define do
  factory :company do
    name { "MyString" }
    subdomain { "MyString" }
    custom_domain { "MyString" }
    logo { "MyString" }
    primary_color { "MyString" }
    secondary_color { "MyString" }
    timezone { "MyString" }
    default_currency { "MyString" }
    business_email { "MyString" }
    business_phone { "MyString" }
    address { "MyText" }
    settings { "" }
    status { 1 }
    subscription_tier { 1 }
    trial_ends_at { "2026-02-26 12:53:39" }
    subscription_started_at { "2026-02-26 12:53:39" }
    subscription_cancelled_at { "2026-02-26 12:53:39" }
    active { false }
    deleted { false }
    deleted_at { "2026-02-26 12:53:39" }
  end
end
