# frozen_string_literal: true

class EmailCampaign < ApplicationRecord
  include ActsAsTenant

  # Enums
  enum :campaign_type, {
    quote_followup: 0,
    customer_reengagement: 1,
    booking_reminder: 2,
    marketing: 3,
    transactional: 4
  }

  enum :status, {
    draft: 0,
    scheduled: 1,
    active: 2,
    paused: 3,
    completed: 4,
    archived: 5
  }

  # Associations
  belongs_to :company
  has_many :email_sequences, dependent: :destroy
  has_many :email_queues, dependent: :nullify

  # Validations
  validates :name, presence: true, length: { maximum: 255 }
  validates :campaign_type, presence: true
  validates :status, presence: true
  validates :delay_hours, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :validate_trigger_conditions

  # Scopes
  scope :active_campaigns, -> { where(status: :active, active: true) }
  scope :by_type, ->(type) { where(campaign_type: type) }
  scope :scheduled_for_date, ->(date) { where('starts_at <= ? AND (ends_at IS NULL OR ends_at >= ?)', date, date) }

  # Callbacks
  after_create :create_default_sequences, if: -> { quote_followup? }

  # Instance methods
  def can_send?
    active? && (active == true) &&
    (starts_at.nil? || starts_at <= Time.current) &&
    (ends_at.nil? || ends_at >= Time.current)
  end

  def metrics
    {
      total_sent: email_queues.count,
      delivered: email_queues.where.not(delivered_at: nil).count,
      opened: email_queues.where.not(opened_at: nil).count,
      clicked: email_queues.where.not(clicked_at: nil).count,
      bounced: email_queues.where.not(bounced_at: nil).count,
      unsubscribed: email_queues.where.not(unsubscribed_at: nil).count
    }
  end

  def open_rate
    sent = email_queues.count
    return 0.0 if sent.zero?

    opened = email_queues.where.not(opened_at: nil).count
    (opened.to_f / sent * 100).round(2)
  end

  def click_rate
    sent = email_queues.count
    return 0.0 if sent.zero?

    clicked = email_queues.where.not(clicked_at: nil).count
    (clicked.to_f / sent * 100).round(2)
  end

  def conversion_rate
    sent = email_queues.count
    return 0.0 if sent.zero?

    # Count bookings created after email sent
    conversions = count_conversions
    (conversions.to_f / sent * 100).round(2)
  end

  def revenue_attributed
    # This would need to track which bookings came from this campaign
    # For now, return 0 - implementation depends on tracking mechanism
    Money.new(0, company.currency || 'USD')
  end

  def pause!
    update!(status: :paused)
  end

  def resume!
    update!(status: :active)
  end

  def complete!
    update!(status: :completed)
  end

  private

  def validate_trigger_conditions
    return if trigger_conditions.blank?

    unless trigger_conditions.is_a?(Hash)
      errors.add(:trigger_conditions, 'must be a valid JSON object')
    end
  end

  def create_default_sequences
    return unless quote_followup?

    # Day 3 follow-up
    email_sequences.create!(
      sequence_number: 1,
      subject_template: "Following up on your quote {{quote_number}}",
      body_template: "Hi {{customer_name}},\n\nI wanted to follow up on the quote we sent you on {{quote_date}}...",
      send_delay_hours: 72, # 3 days
      active: true
    )

    # Day 7 follow-up
    email_sequences.create!(
      sequence_number: 2,
      subject_template: "Your quote {{quote_number}} expires soon",
      body_template: "Hi {{customer_name}},\n\nJust a reminder that your quote expires on {{quote_expires_at}}...",
      send_delay_hours: 168, # 7 days
      active: true
    )
  end

  def count_conversions
    # Implementation would depend on tracking mechanism
    # This is a placeholder
    0
  end
end
