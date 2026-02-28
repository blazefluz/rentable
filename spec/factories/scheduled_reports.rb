FactoryBot.define do
  factory :scheduled_report do
    association :company

    report_type { :profit_loss }
    frequency { :monthly }
    recipients { ['cfo@example.com', 'admin@example.com'] }
    format { :pdf }
    next_send_date { Date.current.next_month.beginning_of_month }
    active { true }

    trait :monthly do
      frequency { :monthly }
      next_send_date { Date.current.next_month.beginning_of_month }
    end

    trait :quarterly do
      frequency { :quarterly }
      next_send_date { Date.current.next_quarter.beginning_of_quarter }
    end

    trait :inactive do
      active { false }
    end
  end
end
