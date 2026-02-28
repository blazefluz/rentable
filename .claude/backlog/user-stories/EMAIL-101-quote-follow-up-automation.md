# User Story: Automated Quote Follow-Up Sequence

**Story ID**: EMAIL-101
**Epic**: [EMAIL - Email Marketing Automation](../epics/EMAIL-email-marketing.md)
**Status**: Ready
**Priority**: CRITICAL (P0)
**Points**: 8
**Sprint**: Sprint 19
**Assigned To**: backend-developer

---

## Story

**As a** Sales Manager
**I want to** automatically send follow-up emails to customers who request quotes but don't book
**So that** I can increase quote-to-booking conversion rate without manual work

---

## Acceptance Criteria

- [ ] **Given** A customer requests a quote
      **When** 24 hours pass with no booking
      **Then** An automated follow-up email is sent with the quote details

- [ ] **Given** A customer received the first follow-up email
      **When** 72 hours pass with no response (no open/click)
      **Then** A second follow-up with FAQ/testimonials is sent

- [ ] **Given** A customer still hasn't booked after 7 days
      **When** The final follow-up window arrives
      **Then** A "last chance" email with 10% discount is sent

- [ ] **Given** A customer books before the sequence completes
      **When** The booking is confirmed
      **Then** All pending follow-up emails are cancelled

- [ ] **Given** Follow-up emails are sent
      **When** Customer opens or clicks
      **Then** Events are tracked for analytics

---

## Technical Details

### Database Schema
```sql
CREATE TABLE email_automations (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id),
  email_template_id BIGINT REFERENCES email_templates(id),

  name VARCHAR(255) NOT NULL,
  trigger VARCHAR(100) NOT NULL,  -- 'quote_created', 'booking_created', etc.
  delay_hours INTEGER NOT NULL DEFAULT 24,

  enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE email_campaign_sends (
  id BIGSERIAL PRIMARY KEY,
  email_automation_id BIGINT REFERENCES email_automations(id),
  customer_id BIGINT NOT NULL REFERENCES customers(id),
  quote_id BIGINT REFERENCES quotes(id),

  -- Tracking
  status VARCHAR(50) DEFAULT 'pending',
  sent_at TIMESTAMP,
  delivered_at TIMESTAMP,
  opened_at TIMESTAMP,
  clicked_at TIMESTAMP,
  bounced_at TIMESTAMP,

  -- External provider IDs
  sendgrid_message_id VARCHAR(255),

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_email_sends_customer ON email_campaign_sends(customer_id);
CREATE INDEX idx_email_sends_status ON email_campaign_sends(status);
```

### Services
```ruby
class EmailAutomationService
  def trigger_quote_follow_up(quote)
    return unless quote.customer.can_receive_marketing_emails?

    # Schedule sequence
    schedule_email(quote, delay: 24.hours, template: :quote_follow_up_1)
    schedule_email(quote, delay: 72.hours, template: :quote_follow_up_2)
    schedule_email(quote, delay: 7.days, template: :quote_follow_up_3_discount)
  end

  def cancel_follow_up_sequence(quote)
    EmailCampaignSend
      .where(quote: quote, status: 'pending')
      .destroy_all
  end

  private

  def schedule_email(quote, delay:, template:)
    automation = EmailAutomation.find_by(
      company: quote.company,
      trigger: 'quote_created',
      email_template: { template_type: template }
    )

    return unless automation&.enabled?

    EmailAutomationJob
      .set(wait: delay)
      .perform_later(automation.id, quote.id)
  end
end

class EmailSendService
  def send_automation_email(automation, quote)
    customer = quote.customer
    template = automation.email_template

    # Render template with data
    html_body = EmailTemplateRenderer.new.render(template, customer, quote: quote)

    # Send via SendGrid
    response = send_via_sendgrid(
      to: customer.email,
      subject: template.subject,
      body: html_body,
      tracking_category: "quote_follow_up_#{automation.id}"
    )

    # Record send
    EmailCampaignSend.create!(
      email_automation: automation,
      customer: customer,
      quote: quote,
      status: 'sent',
      sent_at: Time.current,
      sendgrid_message_id: response['message_id']
    )
  end

  private

  def send_via_sendgrid(to:, subject:, body:, tracking_category:)
    require 'sendgrid-ruby'
    include SendGrid

    mail = Mail.new
    mail.from = Email.new(email: 'no-reply@rentable.com', name: 'Rentable')
    mail.subject = subject

    personalization = Personalization.new
    personalization.add_to(Email.new(email: to))
    personalization.add_custom_arg(CustomArg.new(key: 'category', value: tracking_category))
    mail.add_personalization(personalization)

    mail.add_content(Content.new(type: 'text/html', value: body))

    # Enable tracking
    mail.tracking_settings = TrackingSettings.new
    mail.tracking_settings.click_tracking = ClickTracking.new(enable: true)
    mail.tracking_settings.open_tracking = OpenTracking.new(enable: true)

    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
    response = sg.client.mail._('send').post(request_body: mail.to_json)

    JSON.parse(response.body)
  end
end
```

### Email Templates (Liquid)
```html
<!-- Template 1: 24h follow-up -->
<p>Hi {{ customer_name }},</p>

<p>Thanks for requesting a quote for <strong>{{ quote.product_name }}</strong>!</p>

<p>Your quote details:</p>
<ul>
  <li>Rental Dates: {{ quote.start_date }} - {{ quote.end_date }}</li>
  <li>Total: <strong>{{ quote.total_price }}</strong></li>
</ul>

<p>Ready to book?</p>
<a href="{{ booking_url }}" style="background: #007bff; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px;">
  Confirm Booking
</a>

<p>Questions? Reply to this email or call us at {{ company_phone }}.</p>

<!-- Template 2: 72h follow-up with FAQ -->
<p>Hi {{ customer_name }},</p>

<p>We noticed you haven't booked your rental yet. Need help deciding?</p>

<h3>Frequently Asked Questions</h3>
<ul>
  <li><strong>What's included?</strong> Full setup, delivery, and pickup</li>
  <li><strong>Can I extend?</strong> Yes, subject to availability</li>
  <li><strong>What if it rains?</strong> We offer flexible rescheduling</li>
</ul>

<h3>What Our Customers Say</h3>
<blockquote>
  "Amazing service! Equipment was in perfect condition." - John D.
</blockquote>

<!-- Template 3: 7-day last chance with discount -->
<p>Hi {{ customer_name }},</p>

<p><strong>Last Chance!</strong> Your quote expires soon.</p>

<p>Book today and save 10% with code: <code>BOOK10</code></p>

<p>This offer expires in 24 hours.</p>
```

### Background Job
```ruby
class EmailAutomationJob < ApplicationJob
  queue_as :default

  def perform(automation_id, quote_id)
    automation = EmailAutomation.find(automation_id)
    quote = Quote.find(quote_id)

    # Check if quote was already booked
    if quote.booking.present?
      Rails.logger.info "Quote #{quote_id} already booked, skipping email"
      return
    end

    # Send email
    EmailSendService.new.send_automation_email(automation, quote)
  end
end
```

### Webhook for Tracking (SendGrid)
```ruby
class WebhooksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def sendgrid
    events = params[:_json]

    events.each do |event|
      campaign_send = EmailCampaignSend.find_by(sendgrid_message_id: event['sg_message_id'])
      next unless campaign_send

      case event['event']
      when 'delivered'
        campaign_send.update(status: 'delivered', delivered_at: event['timestamp'])
      when 'open'
        campaign_send.update(status: 'opened', opened_at: event['timestamp'])
      when 'click'
        campaign_send.update(status: 'clicked', clicked_at: event['timestamp'])
      when 'bounce'
        campaign_send.update(status: 'bounced', bounced_at: event['timestamp'])
        campaign_send.customer.update(email_bounced: true)
      end
    end

    head :ok
  end
end
```

---

## Tasks

### Backend Tasks (8 pts)
- [ ] Set up SendGrid account and API key (1h)
- [ ] Create email_automations, email_campaign_sends tables (1h)
- [ ] Create EmailAutomation, EmailCampaignSend models (1h)
- [ ] Implement EmailAutomationService (3h)
- [ ] Implement EmailSendService with SendGrid (3h)
- [ ] Create email templates for 3 follow-ups (2h)
- [ ] Implement SendGrid webhook handler (2h)
- [ ] Add Quote model callback to trigger automation (1h)
- [ ] Write tests (3h)

**Total**: ~17 hours (~8 points)

---

## Dependencies

- **Blocking**: SendGrid account, API key
- **Requires**: Quote model (needs to be created or use Booking model)

---

## Definition of Done

- [ ] Quote follow-up sequence working end-to-end
- [ ] Emails sent at correct intervals (24h, 72h, 7d)
- [ ] Tracking works (opens, clicks)
- [ ] Sequence cancelled when booking created
- [ ] Unsubscribe link functional
- [ ] >85% test coverage

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| 2026-02-28 | Product Owner | Story created |
