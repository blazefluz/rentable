class ClientTagging < ApplicationRecord
  belongs_to :client
  belongs_to :client_tag
  belongs_to :tagged_by, class_name: 'User', foreign_key: 'tagged_by_id', optional: true

  # Validations
  validates :client_id, uniqueness: { scope: :client_tag_id, message: "already has this tag" }

  # Callbacks
  before_create :set_tagged_at

  # Scopes
  scope :recent, -> { order(tagged_at: :desc) }
  scope :by_user, ->(user_id) { where(tagged_by_id: user_id) }

  private

  def set_tagged_at
    self.tagged_at ||= Time.current
  end
end
