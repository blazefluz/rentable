# frozen_string_literal: true

class ProcessEmailWebhookJob < ApplicationJob
  queue_as :default

  def perform(webhook_data)
    event_type = webhook_data['event']
    email_queue_id = extract_email_queue_id(webhook_data)

    return unless email_queue_id

    email_queue = EmailQueue.find_by(id: email_queue_id)
    return unless email_queue

    case event_type
    when 'delivered'
      handle_delivered(email_queue, webhook_data)
    when 'open'
      handle_opened(email_queue, webhook_data)
    when 'click'
      handle_clicked(email_queue, webhook_data)
    when 'bounce', 'dropped'
      handle_bounced(email_queue, webhook_data)
    when 'unsubscribe'
      handle_unsubscribed(email_queue, webhook_data)
    when 'spamreport'
      handle_spam_report(email_queue, webhook_data)
    else
      Rails.logger.info "Unknown webhook event type: #{event_type}"
    end

    # Log communication
    log_communication(email_queue, event_type, webhook_data)
  end

  private

  def extract_email_queue_id(webhook_data)
    # SendGrid sends custom args in the webhook
    webhook_data.dig('email_queue_id') ||
    webhook_data.dig('custom_args', 'email_queue_id')
  end

  def handle_delivered(email_queue, webhook_data)
    email_queue.update!(
      delivered_at: parse_timestamp(webhook_data['timestamp']),
      status: :sent
    )

    Rails.logger.info "Email #{email_queue.id} delivered to #{email_queue.recipient}"
  end

  def handle_opened(email_queue, webhook_data)
    # Only update if this is the first open
    if email_queue.opened_at.nil?
      email_queue.update!(
        opened_at: parse_timestamp(webhook_data['timestamp'])
      )

      Rails.logger.info "Email #{email_queue.id} opened by #{email_queue.recipient}"
    end
  end

  def handle_clicked(email_queue, webhook_data)
    # Only update if this is the first click
    if email_queue.clicked_at.nil?
      email_queue.update!(
        clicked_at: parse_timestamp(webhook_data['timestamp'])
      )

      Rails.logger.info "Email #{email_queue.id} clicked by #{email_queue.recipient} - URL: #{webhook_data['url']}"
    end
  end

  def handle_bounced(email_queue, webhook_data)
    email_queue.update!(
      bounced_at: parse_timestamp(webhook_data['timestamp']),
      bounce_reason: extract_bounce_reason(webhook_data),
      status: :failed
    )

    Rails.logger.warn "Email #{email_queue.id} bounced: #{email_queue.bounce_reason}"

    # Mark email as invalid in client record
    mark_email_invalid(email_queue.recipient, webhook_data)
  end

  def handle_unsubscribed(email_queue, webhook_data)
    email_queue.update!(
      unsubscribed_at: parse_timestamp(webhook_data['timestamp'])
    )

    # Mark client as unsubscribed
    mark_client_unsubscribed(email_queue.recipient)

    Rails.logger.info "#{email_queue.recipient} unsubscribed"
  end

  def handle_spam_report(email_queue, webhook_data)
    Rails.logger.error "Email #{email_queue.id} reported as spam by #{email_queue.recipient}"

    # Mark client as unsubscribed and flag for review
    mark_client_unsubscribed(email_queue.recipient, spam_report: true)
  end

  def parse_timestamp(timestamp)
    return Time.current if timestamp.blank?

    if timestamp.is_a?(String)
      Time.parse(timestamp)
    elsif timestamp.is_a?(Integer)
      Time.at(timestamp)
    else
      Time.current
    end
  rescue StandardError
    Time.current
  end

  def extract_bounce_reason(webhook_data)
    webhook_data['reason'] ||
    webhook_data['type'] ||
    'Unknown bounce reason'
  end

  def mark_email_invalid(email, webhook_data)
    # Find client and mark email as invalid
    client = Client.find_by(email: email)
    return unless client

    # You might want to add a field to track invalid emails
    # client.update(email_valid: false, email_bounce_reason: extract_bounce_reason(webhook_data))
  end

  def mark_client_unsubscribed(email, spam_report: false)
    client = Client.find_by(email: email)
    return unless client

    # You might want to add an unsubscribed field to Client model
    # client.update(unsubscribed: true, unsubscribed_at: Time.current, spam_report: spam_report)

    # Or create a separate unsubscribe record
    create_unsubscribe_record(client, spam_report)
  end

  def create_unsubscribe_record(client, spam_report)
    # This would require an Unsubscribe model
    # Unsubscribe.create!(
    #   client: client,
    #   email: client.email,
    #   unsubscribed_at: Time.current,
    #   spam_report: spam_report
    # )
  end

  def log_communication(email_queue, event_type, webhook_data)
    return unless email_queue.company_id

    # Find the client
    client = Client.find_by(email: email_queue.recipient, company_id: email_queue.company_id)
    return unless client

    # Log in client_communications if that model exists
    if defined?(ClientCommunication)
      ClientCommunication.create!(
        client: client,
        communication_type: :email,
        direction: :outbound,
        subject: email_queue.subject,
        notes: "Email #{event_type}: #{webhook_data['event']}",
        communicated_at: parse_timestamp(webhook_data['timestamp'])
      )
    end
  end
end
