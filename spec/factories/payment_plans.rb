FactoryBot.define do
  factory :payment_plan do
    booking { nil }
    name { "MyString" }
    description { "MyText" }
    total_amount_cents { 1 }
    total_amount_currency { "MyString" }
    down_payment_cents { 1 }
    down_payment_currency { "MyString" }
    installment_amount_cents { 1 }
    installment_amount_currency { "MyString" }
    installment_frequency { 1 }
    number_of_installments { 1 }
    installments_paid { 1 }
    start_date { "2026-02-26" }
    next_payment_date { "2026-02-26" }
    status { 1 }
    active { false }
    payment_method { "MyString" }
    notes { "MyText" }
  end
end
