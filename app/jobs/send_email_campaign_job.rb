# frozen_string_literal: true

class SendEmailCampaignJob < ApplicationJob
  queue_as :default

  def perform(email_campaign_id, client_segment_id = nil)
    email_campaign = EmailCampaign.find(email_campaign_id)

    unless email_campaign.can_send?
      Rails.logger.info "Email campaign #{email_campaign_id} cannot send at this time"
      return
    end

    ActsAsTenant.with_tenant(email_campaign.company) do
      recipients = determine_recipients(email_campaign, client_segment_id)

      Rails.logger.info "Sending campaign #{email_campaign.name} to #{recipients.count} recipients"

      recipients.each do |client|
        send_to_client(email_campaign, client)
      end
    end
  end

  private

  def determine_recipients(email_campaign, client_segment_id)
    if client_segment_id.present?
      segment = ClientSegment.find(client_segment_id)
      segment.clients
    else
      case email_campaign.campaign_type
      when 'quote_followup'
        clients_with_pending_quotes(email_campaign)
      when 'customer_reengagement'
        dormant_clients(email_campaign)
      when 'booking_reminder'
        clients_with_upcoming_bookings(email_campaign)
      else
        Client.where(company: email_campaign.company)
      end
    end
  end

  def send_to_client(email_campaign, client)
    email_campaign.email_sequences.active_sequences.ordered.each do |sequence|
      variables = build_variables(client, email_campaign)

      sequence.schedule_for(
        client.email,
        variables,
        Time.current
      )
    end
  end

  def build_variables(client, email_campaign)
    variables = {
      customer_name: client.name,
      customer_email: client.email,
      company_name: email_campaign.company.name,
      company_phone: email_campaign.company.business_phone,
      company_logo: email_campaign.company.logo
    }

    # Add campaign-specific variables
    case email_campaign.campaign_type
    when 'quote_followup'
      add_quote_variables(variables, client)
    when 'customer_reengagement'
      add_reengagement_variables(variables, client)
    when 'booking_reminder'
      add_booking_variables(variables, client)
    end

    variables
  end

  def add_quote_variables(variables, client)
    latest_quote = client.bookings.quotes.order(created_at: :desc).first
    return variables unless latest_quote

    variables.merge({
      quote_number: latest_quote.quote_number,
      quote_date: latest_quote.created_at.strftime('%B %d, %Y'),
      quote_expires_at: latest_quote.quote_expires_at&.strftime('%B %d, %Y'),
      total_price: latest_quote.total_price.format
    })
  end

  def add_reengagement_variables(variables, client)
    variables.merge({
      last_booking_date: client.last_rental_date&.strftime('%B %d, %Y'),
      days_since_booking: client.days_since_last_rental,
      discount_code: generate_discount_code(client)
    })
  end

  def add_booking_variables(variables, client)
    upcoming_booking = client.bookings.where('start_date > ?', Time.current).order(:start_date).first
    return variables unless upcoming_booking

    variables.merge({
      booking_reference: upcoming_booking.reference_number,
      start_date: upcoming_booking.start_date.strftime('%B %d, %Y'),
      end_date: upcoming_booking.end_date.strftime('%B %d, %Y'),
      products_list: upcoming_booking.booking_line_items.map { |item| item.bookable&.name }.compact.join(', ')
    })
  end

  def clients_with_pending_quotes(email_campaign)
    Client.joins(:bookings)
          .where(company: email_campaign.company)
          .where(bookings: { quote_status: :pending_quotes })
          .distinct
  end

  def dormant_clients(email_campaign)
    Client.where(company: email_campaign.company)
          .where('last_rental_date < ? OR last_rental_date IS NULL', 90.days.ago)
  end

  def clients_with_upcoming_bookings(email_campaign)
    Client.joins(:bookings)
          .where(company: email_campaign.company)
          .where('bookings.start_date BETWEEN ? AND ?', Time.current, 7.days.from_now)
          .distinct
  end

  def generate_discount_code(client)
    # Generate a unique discount code for the client
    "WELCOME_BACK_#{client.id}_#{SecureRandom.hex(4).upcase}"
  end
end
