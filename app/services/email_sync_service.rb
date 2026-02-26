class EmailSyncService
  attr_reader :client, :errors

  def initialize(client)
    @client = client
    @errors = []
  end

  # Sync emails from Gmail API
  def sync_from_gmail(gmail_service, days_back = 30)
    return false unless client.email.present?

    begin
      query = "from:#{client.email} OR to:#{client.email} after:#{days_back.days.ago.to_date}"
      messages = gmail_service.list_user_messages('me', q: query).messages || []

      messages.each do |message|
        process_gmail_message(gmail_service, message.id)
      end

      true
    rescue => e
      @errors << "Gmail sync failed: #{e.message}"
      false
    end
  end

  # Sync from Outlook/Microsoft Graph API
  def sync_from_outlook(graph_service, days_back = 30)
    return false unless client.email.present?

    begin
      filter = "contains(from/emailAddress/address, '#{client.email}') or contains(toRecipients/any(r:r/emailAddress/address, '#{client.email}')"
      messages = graph_service.get_messages(filter: filter, top: 100)

      messages.each do |message|
        process_outlook_message(message)
      end

      true
    rescue => e
      @errors << "Outlook sync failed: #{e.message}"
      false
    end
  end

  # Parse and create communication from email
  def create_from_email(email_data)
    return unless valid_email_data?(email_data)

    # Determine direction
    direction = email_sent_by_us?(email_data[:from]) ? :outbound : :inbound

    # Find or create contact
    contact = find_or_create_contact(email_data[:from])

    # Create communication
    client.client_communications.create!(
      communication_type: :email,
      direction: direction,
      subject: email_data[:subject],
      notes: extract_email_body(email_data[:body]),
      contact: contact,
      communicated_at: email_data[:date] || Time.current,
      user: find_user_for_email(email_data[:from])
    )
  rescue => e
    @errors << "Failed to create communication from email: #{e.message}"
    nil
  end

  private

  def process_gmail_message(gmail_service, message_id)
    message = gmail_service.get_user_message('me', message_id)
    
    email_data = {
      from: extract_header(message, 'From'),
      to: extract_header(message, 'To'),
      subject: extract_header(message, 'Subject'),
      date: Time.at(message.internal_date.to_i / 1000),
      body: extract_gmail_body(message)
    }

    create_from_email(email_data)
  end

  def process_outlook_message(message)
    email_data = {
      from: message.from.email_address.address,
      to: message.to_recipients.map { |r| r.email_address.address }.join(', '),
      subject: message.subject,
      date: Time.parse(message.received_date_time),
      body: message.body.content
    }

    create_from_email(email_data)
  end

  def extract_header(message, header_name)
    header = message.payload.headers.find { |h| h.name == header_name }
    header&.value
  end

  def extract_gmail_body(message)
    if message.payload.body.data
      Base64.decode64(message.payload.body.data.tr('-_', '+/'))
    elsif message.payload.parts
      part = message.payload.parts.find { |p| p.mime_type == 'text/plain' }
      part ? Base64.decode64(part.body.data.tr('-_', '+/')) : ''
    else
      ''
    end
  end

  def extract_email_body(body)
    return '' unless body

    # Strip HTML tags if present
    body = body.gsub(/<[^>]*>/, '') if body.include?('<')
    
    # Limit length
    body.length > 5000 ? body[0..4999] : body
  end

  def find_or_create_contact(email_address)
    return nil unless email_address

    # Extract email from "Name <email>" format
    email = email_address.match(/<(.+)>/)&.captures&.first || email_address
    
    contact = client.contacts.find_by(email: email)
    return contact if contact

    # Create new contact if doesn't exist
    name_parts = extract_name_from_email(email_address)
    client.contacts.create!(
      first_name: name_parts[:first_name],
      last_name: name_parts[:last_name],
      email: email
    )
  rescue
    nil
  end

  def extract_name_from_email(email_string)
    if email_string.include?('<')
      # "John Doe <john@example.com>" format
      name = email_string.split('<').first.strip.gsub('"', '')
      parts = name.split(' ')
      {
        first_name: parts.first || 'Unknown',
        last_name: parts.length > 1 ? parts[1..-1].join(' ') : ''
      }
    else
      # Just email address
      username = email_string.split('@').first
      {
        first_name: username.capitalize,
        last_name: ''
      }
    end
  end

  def email_sent_by_us?(from_email)
    # Check if email is from one of our users
    our_domains = ['@example.com'] # Configure your domains
    our_domains.any? { |domain| from_email.include?(domain) }
  end

  def find_user_for_email(email_address)
    email = email_address.match(/<(.+)>/)&.captures&.first || email_address
    User.find_by(email: email)
  end

  def valid_email_data?(data)
    data.is_a?(Hash) && data[:from].present? && data[:subject].present?
  end
end
