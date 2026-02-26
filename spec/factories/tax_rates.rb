FactoryBot.define do
  factory :tax_rate do
    name { "MyString" }
    tax_code { "MyString" }
    tax_type { 1 }
    calculation_method { 1 }
    rate { "9.99" }
    country { "MyString" }
    state { "MyString" }
    city { "MyString" }
    zip_code_pattern { "MyString" }
    active { false }
    start_date { "2026-02-26" }
    end_date { "2026-02-26" }
    applies_to_shipping { false }
    applies_to_deposits { false }
    minimum_amount_cents { 1 }
    maximum_amount_cents { 1 }
    compound { false }
    position { 1 }
    rate_cents { 1 }
  end
end
