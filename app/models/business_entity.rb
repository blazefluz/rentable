class BusinessEntity < ApplicationRecord
  include ActsAsTenant

  belongs_to :client
  has_many :addresses, as: :addressable, dependent: :destroy

  scope :active, -> { where(active: true, deleted: [false, nil]) }

  validates :name, presence: true

  after_initialize :set_defaults

  private

  def set_defaults
    self.active ||= true
    self.deleted ||= false
  end
end
