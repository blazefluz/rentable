FactoryBot.define do
  factory :client_user do
    client { nil }
    contact { nil }
    email { "MyString" }
    encrypted_password { "MyString" }
    password_reset_token { "MyString" }
    password_reset_sent_at { "2026-02-26 00:11:03" }
    last_sign_in_at { "2026-02-26 00:11:03" }
    sign_in_count { 1 }
    current_sign_in_ip { "MyString" }
    last_sign_in_ip { "MyString" }
    confirmed_at { "2026-02-26 00:11:03" }
    confirmation_token { "MyString" }
    confirmation_sent_at { "2026-02-26 00:11:03" }
    active { false }
  end
end
