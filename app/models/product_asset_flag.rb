class ProductAssetFlag < ApplicationRecord
  belongs_to :product
  belongs_to :asset_flag
end
