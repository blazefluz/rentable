FactoryBot.define do
  factory :contract do
    booking { nil }
    contract_type { 1 }
    title { "MyString" }
    content { "MyText" }
    version { "MyString" }
    effective_date { "2026-02-25" }
    expiry_date { "2026-02-25" }
    status { 1 }
    terms_url { "MyString" }
    pdf_file { "MyString" }
    requires_signature { false }
    template { false }
    template_name { "MyString" }
    variables { "" }
    deleted { false }
  end
end
