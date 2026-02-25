FactoryBot.define do
  factory :project_type do
    name { "MyString" }
    description { "MyText" }
    feature_flags { "" }
    settings { "" }
    active { false }
    default_duration_days { 1 }
    requires_approval { false }
    auto_confirm { false }
    deleted { false }
  end
end
