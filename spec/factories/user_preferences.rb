FactoryBot.define do
  factory :user_preference do
    user { nil }
    preferences { "" }
    widgets { "" }
  end
end
