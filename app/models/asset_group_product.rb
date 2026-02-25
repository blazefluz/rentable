class AssetGroupProduct < ApplicationRecord
  belongs_to :asset_group
  belongs_to :product
end
