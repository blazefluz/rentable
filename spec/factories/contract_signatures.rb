FactoryBot.define do
  factory :contract_signature do
    contract { nil }
    user { nil }
    signer_name { "MyString" }
    signer_email { "MyString" }
    signer_role { 1 }
    signature_data { "MyText" }
    signature_type { 1 }
    ip_address { "MyString" }
    user_agent { "MyString" }
    signed_at { "2026-02-25 23:33:17" }
    accepted_terms { false }
    terms_version { "MyString" }
    witness_name { "MyString" }
    witness_signature { "MyText" }
    deleted { false }
  end
end
