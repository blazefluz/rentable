# frozen_string_literal: true

class EmailSequence < ApplicationRecord
  # Associations
  belongs_to :email_campaign
  has_many :email_queues, dependent: :nullify

  # Validations
  validates :email_campaign, presence: true
  validates :sequence_number, presence: true, numericality: { greater_than: 0 }
  validates :subject_template, presence: true
  validates :body_template, presence: true
  validates :send_delay_hours, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :active_sequences, -> { where(active: true) }
  scope :ordered, -> { order(:sequence_number) }

  # Instance methods
  def can_send?
    active? && email_campaign.can_send?
  end

  def substitute_variables(template, variables = {})
    result = template.dup
    variables.each do |key, value|
      placeholder = "{{#{key}}}"
      result.gsub!(placeholder, value.to_s) if result.include?(placeholder)
    end
    result
  end

  def render_subject(variables = {})
    substitute_variables(subject_template, variables)
  end

  def render_body(variables = {})
    substitute_variables(body_template, variables)
  end

  def schedule_for(recipient, variables = {}, trigger_time = Time.current)
    return unless can_send?

    scheduled_time = trigger_time + send_delay_hours.hours

    EmailQueue.create!(
      company: email_campaign.company,
      recipient: recipient,
      subject: render_subject(variables),
      body: render_body(variables),
      status: :pending,
      email_campaign: email_campaign,
      email_sequence: self,
      metadata: {
        variables: variables,
        trigger_time: trigger_time.iso8601,
        scheduled_time: scheduled_time.iso8601
      }.to_json
    )
  end

  def metrics
    {
      total_sent: email_queues.count,
      delivered: email_queues.where.not(delivered_at: nil).count,
      opened: email_queues.where.not(opened_at: nil).count,
      clicked: email_queues.where.not(clicked_at: nil).count,
      bounced: email_queues.where.not(bounced_at: nil).count
    }
  end

  def open_rate
    sent = email_queues.count
    return 0.0 if sent.zero?

    opened = email_queues.where.not(opened_at: nil).count
    (opened.to_f / sent * 100).round(2)
  end
end
