class Note < ApplicationRecord
  belongs_to :notable, polymorphic: true
  belongs_to :user, optional: true

  enum :note_type, {
    general: 0,
    important: 1,
    todo: 2,
    meeting: 3,
    followup: 4
  }

  scope :active, -> { where(deleted: [false, nil]) }
  scope :pinned, -> { where(pinned: true) }

  validates :content, presence: true

  after_initialize :set_defaults

  private

  def set_defaults
    self.deleted ||= false
    self.pinned ||= false
    self.note_type ||= :general
  end
end
