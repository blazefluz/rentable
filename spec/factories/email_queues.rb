FactoryBot.define do
  factory :email_queue do
    recipient { "MyString" }
    subject { "MyString" }
    body { "MyText" }
    status { 1 }
    sent_at { "2026-02-25 18:44:03" }
    error_message { "MyText" }
    attempts { 1 }
    last_attempt_at { "2026-02-25 18:44:03" }
    instance { nil }
    metadata { "" }
  end
end
