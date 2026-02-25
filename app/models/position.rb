class Position < ApplicationRecord
  belongs_to :instance
  has_many :user_positions, dependent: :destroy
  has_many :users, through: :user_positions

  validates :name, presence: true
  validates :rank, numericality: { only_integer: true }, allow_nil: true

  scope :active, -> { where(deleted: [false, nil]) }
  scope :by_rank, -> { order(rank: :desc) }

  after_initialize :set_defaults

  def higher_rank_than?(other_position)
    return false unless rank && other_position&.rank
    rank > other_position.rank
  end

  private

  def set_defaults
    self.deleted ||= false
  end
end
