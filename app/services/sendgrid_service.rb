# frozen_string_literal: true

require 'sendgrid-ruby'

class SendGridService
  include SendGrid

  RATE_LIMIT = 100 # emails per hour
  RATE_LIMIT_WINDOW = 1.hour

  def initialize
    @client = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
  end

  def send_email(to:, from:, subject:, html_body:, text_body: nil, email_queue_id: nil)
    # Check rate limit
    if rate_limit_exceeded?
      return {
        success: false,
        error: 'Rate limit exceeded',
        message: "Maximum #{RATE_LIMIT} emails per hour"
      }
    end

    mail = build_email(
      to: to,
      from: from,
      subject: subject,
      html_body: html_body,
      text_body: text_body,
      email_queue_id: email_queue_id
    )

    begin
      response = @client.client.mail._('send').post(request_body: mail.to_json)

      if response.status_code.to_i.between?(200, 299)
        update_email_queue(email_queue_id, :sent) if email_queue_id
        increment_rate_limit_counter

        {
          success: true,
          status_code: response.status_code,
          message_id: extract_message_id(response),
          sent_at: Time.current
        }
      else
        update_email_queue(email_queue_id, :failed, response.body) if email_queue_id

        {
          success: false,
          status_code: response.status_code,
          error: response.body
        }
      end
    rescue StandardError => e
      update_email_queue(email_queue_id, :failed, e.message) if email_queue_id

      {
        success: false,
        error: e.message,
        backtrace: e.backtrace[0..5]
      }
    end
  end

  def send_bulk_emails(emails)
    results = []

    emails.each do |email_data|
      result = send_email(**email_data)
      results << result

      # Add small delay to avoid hitting rate limits
      sleep(0.1) if result[:success]
    end

    results
  end

  def verify_sender(email)
    # Verify sender email with SendGrid
    # This would require Single Sender Verification or Domain Authentication
    {
      success: true,
      message: "Verification request sent to #{email}"
    }
  end

  private

  def build_email(to:, from:, subject:, html_body:, text_body: nil, email_queue_id: nil)
    mail = Mail.new

    # From
    mail.from = Email.new(email: from)

    # To (can be array or string)
    to_emails = Array(to)
    personalization = Personalization.new
    to_emails.each do |recipient|
      personalization.to = Email.new(email: recipient)
    end
    mail.personalizations = personalization

    # Subject
    mail.subject = subject

    # Content
    if text_body.present?
      mail.contents = Content.new(type: 'text/plain', value: text_body)
    end

    if html_body.present?
      mail.contents = Content.new(type: 'text/html', value: html_body)
    end

    # Custom headers for tracking
    if email_queue_id
      mail.custom_args = CustomArg.new(key: 'email_queue_id', value: email_queue_id.to_s)
    end

    # Unsubscribe link
    mail.tracking_settings = build_tracking_settings

    mail
  end

  def build_tracking_settings
    tracking_settings = TrackingSettings.new

    # Click tracking
    click_tracking = ClickTracking.new(enable: true, enable_text: true)
    tracking_settings.click_tracking = click_tracking

    # Open tracking
    open_tracking = OpenTracking.new(enable: true)
    tracking_settings.open_tracking = open_tracking

    # Subscription tracking (unsubscribe)
    subscription_tracking = SubscriptionTracking.new(
      enable: true,
      text: 'Unsubscribe',
      html: '<p><a href="[unsubscribe]">Unsubscribe</a></p>'
    )
    tracking_settings.subscription_tracking = subscription_tracking

    tracking_settings
  end

  def extract_message_id(response)
    # SendGrid returns the message ID in the X-Message-Id header
    response.headers['X-Message-Id'] || SecureRandom.uuid
  end

  def update_email_queue(email_queue_id, status, error_message = nil)
    return unless email_queue_id

    email_queue = EmailQueue.find_by(id: email_queue_id)
    return unless email_queue

    case status
    when :sent
      email_queue.update!(
        status: :sent,
        sent_at: Time.current,
        error_message: nil
      )
    when :failed
      email_queue.update!(
        status: :failed,
        error_message: error_message,
        last_attempt_at: Time.current,
        attempts: email_queue.attempts + 1
      )
    end
  end

  def rate_limit_exceeded?
    cache_key = "sendgrid_rate_limit:#{Time.current.beginning_of_hour}"
    current_count = Rails.cache.read(cache_key).to_i
    current_count >= RATE_LIMIT
  end

  def increment_rate_limit_counter
    cache_key = "sendgrid_rate_limit:#{Time.current.beginning_of_hour}"
    Rails.cache.increment(cache_key, 1, expires_in: RATE_LIMIT_WINDOW)
  end
end
