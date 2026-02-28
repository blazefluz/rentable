FactoryBot.define do
  factory :financial_report do
    association :company
    association :generated_by, factory: :user

    report_type { :profit_loss }
    period_type { :monthly }
    start_date { Date.current.beginning_of_month }
    end_date { Date.current.end_of_month }

    data do
      {
        period: { start_date: start_date, end_date: end_date, days: 30 },
        revenue: { total: 100000, rental: 80000, sales: 20000 },
        cost_of_goods_sold: { total: 30000, equipment_depreciation: 20000, direct_labor: 10000 },
        gross_profit: 70000,
        operating_expenses: { total: 40000, maintenance: 15000, delivery: 10000, marketing: 15000 },
        operating_income: 30000,
        other_income_expenses: { total: 0 },
        net_income: 30000,
        metrics: { gross_margin_percentage: 70.0, net_margin_percentage: 30.0 }
      }
    end

    trait :profit_loss do
      report_type { :profit_loss }
    end

    trait :revenue_breakdown do
      report_type { :revenue_breakdown }
      data do
        {
          categories: [
            { name: 'Cameras', revenue: 50000, percentage: 50.0 },
            { name: 'Lenses', revenue: 30000, percentage: 30.0 }
          ],
          total_revenue: 100000
        }
      end
    end
  end
end
