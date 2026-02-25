FactoryBot.define do
  factory :sales_task do
    client { nil }
    user { nil }
    title { "MyString" }
    description { "MyText" }
    task_type { 1 }
    priority { 1 }
    status { 1 }
    due_date { "2026-02-25 18:20:12" }
    completed_date { "2026-02-25 18:20:12" }
    deleted { false }
  end
end
