FactoryBot.define do
  factory :insurance_certificate do
    product { nil }
    policy_number { "MyString" }
    provider { "MyString" }
    coverage_amount_cents { 1 }
    coverage_amount_currency { "MyString" }
    start_date { "2026-02-25" }
    end_date { "2026-02-25" }
    certificate_file { "MyString" }
    notes { "MyText" }
    deleted { false }
  end
end
