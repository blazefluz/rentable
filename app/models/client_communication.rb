class ClientCommunication < ApplicationRecord
  belongs_to :client
  belongs_to :user
  belongs_to :contact, optional: true

  # Enums
  enum :communication_type, {
    email: 0,
    phone_call: 1,
    meeting: 2,
    sms: 3,
    video_call: 4,
    site_visit: 5,
    other: 10
  }

  enum :direction, {
    inbound: 0,
    outbound: 1
  }

  # Validations
  validates :communication_type, presence: true
  validates :direction, presence: true
  validates :communicated_at, presence: true
  validates :subject, presence: true, length: { maximum: 255 }
  validates :notes, length: { maximum: 5000 }

  # Scopes
  scope :recent, -> { order(communicated_at: :desc) }
  scope :by_type, ->(type) { where(communication_type: type) }
  scope :inbound_communications, -> { where(direction: :inbound) }
  scope :outbound_communications, -> { where(direction: :outbound) }
  scope :with_contact, -> { where.not(contact_id: nil) }
  scope :since, ->(date) { where('communicated_at >= ?', date) }
  scope :between, ->(start_date, end_date) { where(communicated_at: start_date..end_date) }

  # Callbacks
  after_create :update_client_last_activity

  # Instance methods
  def summary
    "#{communication_type.humanize} - #{direction.humanize}: #{subject}"
  end

  def duration_display
    return nil unless notes.present?

    # Try to extract duration from notes if mentioned
    if notes =~ /(\d+)\s*(minute|min|hour|hr)/i
      $1 + " " + $2
    end
  end

  def has_attachment?
    attachment.present?
  end

  private

  def update_client_last_activity
    client.touch(:last_activity_at)
  end
end
