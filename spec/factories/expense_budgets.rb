FactoryBot.define do
  factory :expense_budget do
    association :company

    category { :maintenance }
    period_type { :monthly }
    budgeted_amount_cents { 50000 }
    budgeted_amount_currency { 'USD' }
    start_date { Date.current.beginning_of_month }
    end_date { Date.current.end_of_month }

    trait :monthly do
      period_type { :monthly }
      start_date { Date.current.beginning_of_month }
      end_date { Date.current.end_of_month }
    end

    trait :quarterly do
      period_type { :quarterly }
      start_date { Date.current.beginning_of_quarter }
      end_date { Date.current.end_of_quarter }
      budgeted_amount_cents { 150000 }
    end

    trait :annual do
      period_type { :annual }
      start_date { Date.current.beginning_of_year }
      end_date { Date.current.end_of_year }
      budgeted_amount_cents { 600000 }
    end
  end
end
