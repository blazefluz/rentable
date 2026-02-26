FactoryBot.define do
  factory :service_agreement do
    client { nil }
    name { "MyString" }
    agreement_type { 1 }
    start_date { "2026-02-26" }
    end_date { "2026-02-26" }
    renewal_type { 1 }
    minimum_commitment_cents { 1 }
    minimum_commitment_currency { "MyString" }
    payment_schedule { 1 }
    discount_percentage { "9.99" }
    notes { "MyText" }
    active { false }
    auto_renew { false }
  end
end
