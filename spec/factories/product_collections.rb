FactoryBot.define do
  factory :product_collection do
    name { "MyString" }
    slug { "MyString" }
    description { "MyText" }
    short_description { "MyString" }
    parent_collection_id { "" }
    collection_type { 1 }
    visibility { 1 }
    position { 1 }
    active { false }
    featured { false }
    product_count { 1 }
    meta_title { "MyString" }
    meta_description { "MyText" }
    start_date { "2026-02-26" }
    end_date { "2026-02-26" }
    icon { "MyString" }
    color { "MyString" }
    display_template { "MyString" }
    rules { "" }
    is_dynamic { false }
  end
end
