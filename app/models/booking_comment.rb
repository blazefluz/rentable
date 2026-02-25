class BookingComment < ApplicationRecord
  # Associations
  belongs_to :booking
  belongs_to :user

  # Validations
  validates :content, presence: true

  # Scopes
  scope :active, -> { where(deleted: false) }
  scope :recent_first, -> { order(created_at: :desc) }

  # Soft delete
  def soft_delete!
    update(deleted: true)
  end
end
