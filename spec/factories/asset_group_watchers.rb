FactoryBot.define do
  factory :asset_group_watcher do
    user { nil }
    asset_group { nil }
    notify_on_change { false }
    deleted { false }
  end
end
