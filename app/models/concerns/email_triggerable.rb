# frozen_string_literal: true

module EmailTriggerable
  extend ActiveSupport::Concern

  included do
    after_commit :trigger_quote_followup_campaign, on: [:create, :update], if: :should_trigger_quote_followup?
    after_commit :trigger_booking_reminder_campaign, on: [:create, :update], if: :should_trigger_booking_reminder?
  end

  private

  def should_trigger_quote_followup?
    return false unless respond_to?(:quote_status)
    return false unless company_id.present?

    # Trigger when quote is first sent
    saved_change_to_quote_status? && quote_status == 'pending_quotes'
  end

  def should_trigger_booking_reminder?
    return false unless company_id.present?
    return false unless respond_to?(:status)

    # Trigger when booking is confirmed
    saved_change_to_status? && status == 'confirmed'
  end

  def trigger_quote_followup_campaign
    ActsAsTenant.with_tenant(company) do
      campaign = EmailCampaign.active_campaigns
                              .where(campaign_type: :quote_followup)
                              .first

      return unless campaign&.can_send?

      # Schedule the email sequence
      schedule_quote_followup_emails(campaign)
    end
  end

  def trigger_booking_reminder_campaign
    ActsAsTenant.with_tenant(company) do
      campaign = EmailCampaign.active_campaigns
                              .where(campaign_type: :booking_reminder)
                              .first

      return unless campaign&.can_send?

      # Schedule the email sequence
      schedule_booking_reminder_emails(campaign)
    end
  end

  def schedule_quote_followup_emails(campaign)
    # Get the client
    client_email = customer_email || client&.email
    return unless client_email.present?

    campaign.email_sequences.active_sequences.ordered.each do |sequence|
      variables = build_quote_variables

      sequence.schedule_for(
        client_email,
        variables,
        Time.current
      )
    end
  end

  def schedule_booking_reminder_emails(campaign)
    # Get the client
    client_email = customer_email || client&.email
    return unless client_email.present?

    campaign.email_sequences.active_sequences.ordered.each do |sequence|
      variables = build_booking_variables

      sequence.schedule_for(
        client_email,
        variables,
        Time.current
      )
    end
  end

  def build_quote_variables
    {
      customer_name: customer_name,
      customer_email: customer_email,
      quote_number: quote_number,
      quote_date: created_at.strftime('%B %d, %Y'),
      quote_expires_at: quote_expires_at&.strftime('%B %d, %Y'),
      total_price: total_price&.format || '$0.00',
      company_name: company&.name,
      company_phone: company&.business_phone,
      company_logo: company&.logo
    }
  end

  def build_booking_variables
    {
      customer_name: customer_name,
      customer_email: customer_email,
      booking_reference: reference_number,
      start_date: start_date.strftime('%B %d, %Y'),
      end_date: end_date.strftime('%B %d, %Y'),
      total_price: total_price&.format || '$0.00',
      products_list: booking_line_items.map { |item| item.bookable&.name }.compact.join(', '),
      company_name: company&.name,
      company_phone: company&.business_phone,
      company_logo: company&.logo
    }
  end
end
