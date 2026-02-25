FactoryBot.define do
  factory :note do
    notable { nil }
    user { nil }
    title { "MyString" }
    content { "MyText" }
    note_type { 1 }
    pinned { false }
    deleted { false }
  end
end
