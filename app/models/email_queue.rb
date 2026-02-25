class EmailQueue < ApplicationRecord
  include ActsAsTenant

  enum :status, {
    pending: 0,
    processing: 1,
    sent: 2,
    failed: 3,
    cancelled: 4
  }

  # Scopes
  scope :ready_to_send, -> { where(status: :pending).where('attempts < ?', 5) }
  scope :failed_permanently, -> { where(status: :failed).where('attempts >= ?', 5) }
  scope :recent_failures, -> { where(status: :failed).where('last_attempt_at > ?', 24.hours.ago) }

  # Validations
  validates :recipient, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :subject, presence: true
  validates :body, presence: true

  after_initialize :set_defaults

  # Send email with retry logic
  def send_email!
    return false if cancelled? || attempts >= 5

    update(status: :processing, attempts: attempts + 1, last_attempt_at: Time.current)

    begin
      # Here you would integrate with your mailer
      # Example: EmailQueueMailer.send_email(self).deliver_now
      
      # For now, simulate sending
      if simulate_send
        update(status: :sent, sent_at: Time.current, error_message: nil)
        true
      else
        raise StandardError, "Failed to send email"
      end
    rescue StandardError => e
      update(
        status: :failed,
        error_message: "#{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
      )
      false
    end
  end

  # Retry failed email
  def retry!
    return false if attempts >= 5
    update(status: :pending)
    send_email!
  end

  # Cancel email
  def cancel!
    update(status: :cancelled) unless sent?
  end

  # Check if should retry
  def should_retry?
    failed? && attempts < 5 && last_attempt_at < 1.hour.ago
  end

  # Get metadata value
  def get_metadata(key)
    return nil unless metadata.is_a?(Hash)
    metadata[key.to_s]
  end

  # Set metadata value
  def set_metadata(key, value)
    self.metadata ||= {}
    self.metadata[key.to_s] = value
  end

  private

  def set_defaults
    self.status ||= :pending
    self.attempts ||= 0
    self.metadata ||= {}
  end

  def simulate_send
    # In production, this would actually send the email
    # For now, return true to simulate success
    true
  end
end
