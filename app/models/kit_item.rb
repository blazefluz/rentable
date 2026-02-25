# app/models/kit_item.rb
class KitItem < ApplicationRecord
  belongs_to :kit
  belongs_to :product

  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :product_id, uniqueness: { scope: :kit_id }
end
