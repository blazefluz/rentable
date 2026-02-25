FactoryBot.define do
  factory :invitation_code do
    code { "MyString" }
    instance { nil }
    created_by { nil }
    max_uses { 1 }
    current_uses { 1 }
    expires_at { "2026-02-25 18:25:33" }
    deleted { false }
  end
end
