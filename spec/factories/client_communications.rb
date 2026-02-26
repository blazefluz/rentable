FactoryBot.define do
  factory :client_communication do
    client { nil }
    user { nil }
    contact { nil }
    communication_type { 1 }
    direction { 1 }
    subject { "MyString" }
    notes { "MyText" }
    communicated_at { "2026-02-25 23:52:58" }
    attachment { "MyString" }
  end
end
