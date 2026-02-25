FactoryBot.define do
  factory :comment do
    commentable { nil }
    user { nil }
    parent_comment { nil }
    content { "MyText" }
    upvotes_count { 1 }
    deleted { false }
    instance { nil }
  end
end
