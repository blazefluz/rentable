FactoryBot.define do
  factory :maintenance_schedule do
    association :product
    association :company
    association :assigned_to, factory: :user

    name { "#{Faker::Lorem.words(number: 2).join(' ').titleize} Maintenance" }
    description { Faker::Lorem.sentence }
    frequency { :days_based }
    interval_value { 30 }
    interval_unit { 'days' }
    next_due_date { 30.days.from_now }
    status { :scheduled }
    enabled { true }

    trait :hours_based do
      frequency { :hours_based }
      interval_value { 100 }
      interval_unit { 'hours' }
      next_due_date { 100.hours.from_now }
    end

    trait :usage_based do
      frequency { :usage_based }
      interval_value { 50 }
      interval_unit { 'rentals' }
      next_due_date { 30.days.from_now }
    end

    trait :due_soon do
      next_due_date { 3.days.from_now }
    end

    trait :overdue do
      next_due_date { 5.days.ago }
      status { :overdue }
    end

    trait :completed do
      status { :completed }
      last_completed_at { 2.days.ago }
    end

    trait :disabled do
      enabled { false }
    end

    trait :in_progress do
      status { :in_progress }
    end
  end
end
