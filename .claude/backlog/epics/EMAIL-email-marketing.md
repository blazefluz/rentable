# Epic: Email Marketing Automation

**Epic ID**: EMAIL
**Status**: Backlog
**Priority**: CRITICAL
**Business Value**: HIGH
**Target Release**: Phase 1 - Q2 2026

---

## Overview

Automated email marketing and customer communication system to nurture leads, re-engage past customers, promote seasonal campaigns, and increase booking conversion rates. Includes drip campaigns, segmentation, and analytics.

## Business Problem

Current challenges:
- No automated follow-up with quote requests → 60% quote abandonment
- Past customers forgotten → Only 15% repeat booking rate (industry avg: 35%)
- Manual email campaigns take 8+ hours per week
- No visibility into email performance (open rates, conversions)
- Missed opportunities for seasonal promotions (summer party season, graduation)
- Generic messaging not personalized to customer needs

**Cost of Inaction**: Losing $50K-100K annually in repeat business and abandoned quotes

## Success Metrics

- **Primary**: Increase conversion rate from quote to booking by 20%
- **Secondary**:
  - 30% repeat booking rate (up from 15%)
  - 40% email open rate, 10% click-through rate
  - Reduce time spent on email marketing by 80% (automation)
  - 25% of revenue from automated email campaigns

## User Personas

1. **Marketing Manager** - Creates campaigns, analyzes performance
2. **Sales Rep** - Follows up on leads, sends personalized quotes
3. **Customer** - Receives relevant, timely email communications
4. **Business Owner** - Wants more revenue from existing customer base

---

## User Stories

### Must Have (P0)
- [ ] EMAIL-101: Automated quote follow-up sequence (8 pts)
- [ ] EMAIL-102: Past customer re-engagement campaign (5 pts)
- [ ] EMAIL-103: Email template builder with drag-and-drop (8 pts)
- [ ] EMAIL-104: Customer segmentation (by product type, spend, location) (5 pts)
- [ ] EMAIL-105: Email analytics dashboard (open rate, click rate, conversions) (5 pts)

### Should Have (P1)
- [ ] EMAIL-106: Seasonal/holiday campaign scheduler (5 pts)
- [ ] EMAIL-107: Abandoned booking recovery emails (5 pts)
- [ ] EMAIL-108: Post-rental review request emails (3 pts)
- [ ] EMAIL-109: Referral program emails (5 pts)
- [ ] EMAIL-110: SMS marketing integration (Twilio) (8 pts)

### Nice to Have (P2)
- [ ] EMAIL-111: A/B testing for email campaigns (8 pts)
- [ ] EMAIL-112: Email list management (import/export, unsubscribe) (3 pts)
- [ ] EMAIL-113: Integration with Mailchimp/SendGrid (5 pts)
- [ ] EMAIL-114: Personalization tokens (firstname, last_rental, etc.) (3 pts)
- [ ] EMAIL-115: Birthday/anniversary campaigns (3 pts)

**Total Story Points**: 77 pts (Must Have: 31 pts)

---

## Technical Architecture

### New Models
```ruby
class EmailCampaign < ApplicationRecord
  belongs_to :company
  belongs_to :created_by, class_name: 'User'
  has_many :email_campaign_sends

  enum status: [:draft, :scheduled, :sending, :completed, :paused]
  enum campaign_type: [:one_time, :automated_drip, :trigger_based]

  validates :subject, :from_email, :from_name, presence: true
end

class EmailTemplate < ApplicationRecord
  belongs_to :company

  enum template_type: [:quote_follow_up, :booking_confirmation,
                       :review_request, :re_engagement, :custom]

  # HTML body with Liquid template syntax
  validates :html_body, presence: true
end

class EmailCampaignSend < ApplicationRecord
  belongs_to :email_campaign
  belongs_to :customer

  enum status: [:pending, :sent, :delivered, :opened, :clicked, :bounced, :unsubscribed]

  # Tracking
  validates :sent_at, presence: true, if: -> { sent? || delivered? }
end

class CustomerSegment < ApplicationRecord
  belongs_to :company

  # Segment rules stored as JSON
  # e.g., { "total_bookings": { "gte": 3 }, "last_booking_date": { "lt": "90_days_ago" } }
  validates :name, :rules, presence: true
end

class EmailAutomation < ApplicationRecord
  belongs_to :company
  belongs_to :email_template

  enum trigger: [:quote_created, :booking_created, :booking_completed,
                 :days_after_booking, :days_since_last_booking]

  # Delay configuration (e.g., send 24 hours after trigger)
  validates :delay_hours, presence: true
end
```

### New Tables
- `email_campaigns` - Campaign definitions
- `email_templates` - Reusable email templates
- `email_campaign_sends` - Individual email sends and tracking
- `customer_segments` - Customer groups for targeting
- `email_automations` - Trigger-based email rules
- `email_events` - Detailed event log (opens, clicks, bounces)

### API Endpoints
```
# Campaigns
GET    /api/v1/email_campaigns              # List campaigns
POST   /api/v1/email_campaigns              # Create campaign
GET    /api/v1/email_campaigns/:id          # Campaign details
PATCH  /api/v1/email_campaigns/:id          # Update campaign
DELETE /api/v1/email_campaigns/:id          # Delete campaign
POST   /api/v1/email_campaigns/:id/send     # Send/schedule campaign

# Templates
GET    /api/v1/email_templates              # List templates
POST   /api/v1/email_templates              # Create template
GET    /api/v1/email_templates/:id          # Template details
PATCH  /api/v1/email_templates/:id          # Update template

# Segments
GET    /api/v1/customer_segments            # List segments
POST   /api/v1/customer_segments            # Create segment
GET    /api/v1/customer_segments/:id/preview # Preview customers in segment

# Analytics
GET    /api/v1/email_campaigns/:id/analytics # Campaign performance
GET    /api/v1/email_analytics/overview      # Overall email metrics

# Automations
GET    /api/v1/email_automations             # List automations
POST   /api/v1/email_automations             # Create automation
PATCH  /api/v1/email_automations/:id/toggle  # Enable/disable
```

### Services
```ruby
class EmailSendService
  # Send emails via SendGrid/Postmark
  def send_campaign_email(campaign, customer)
    # 1. Render template with customer data
    # 2. Send via email provider
    # 3. Record in email_campaign_sends
    # 4. Track delivery status
  end

  def send_transactional_email(template, recipient, data)
    # For triggered emails (quote follow-up, etc.)
  end
end

class EmailTemplateRenderer
  # Render Liquid templates with customer data
  def render(template, customer, booking: nil)
    context = {
      'customer_name' => customer.name,
      'customer_email' => customer.email,
      'last_booking_date' => customer.bookings.last&.start_date,
      'booking' => booking&.as_json
    }

    Liquid::Template.parse(template.html_body).render(context)
  end
end

class CustomerSegmentationService
  # Evaluate segment rules and return matching customers
  def customers_in_segment(segment)
    customers = Customer.where(company: segment.company)

    segment.rules.each do |field, conditions|
      customers = apply_condition(customers, field, conditions)
    end

    customers
  end

  private

  def apply_condition(customers, field, conditions)
    # e.g., { "total_bookings": { "gte": 3 } }
    case field
    when 'total_bookings'
      customers.having("COUNT(bookings.id) >= ?", conditions['gte'])
    when 'last_booking_date'
      # Complex date logic
    end
  end
end

class EmailAnalyticsService
  # Track email performance
  def campaign_metrics(campaign)
    sends = campaign.email_campaign_sends

    {
      sent: sends.count,
      delivered: sends.delivered.count,
      opened: sends.opened.count,
      clicked: sends.clicked.count,
      bounced: sends.bounced.count,
      unsubscribed: sends.unsubscribed.count,
      open_rate: (sends.opened.count.to_f / sends.delivered.count * 100).round(2),
      click_rate: (sends.clicked.count.to_f / sends.opened.count * 100).round(2),
      conversions: sends.joins(:customer).where.not(bookings: { id: nil }).count
    }
  end
end

class EmailAutomationService
  # Process automation triggers
  def trigger_automation(event, record)
    automations = EmailAutomation.where(trigger: event, enabled: true)

    automations.each do |automation|
      EmailAutomationJob.set(wait: automation.delay_hours.hours)
        .perform_later(automation.id, record.id)
    end
  end
end
```

### Background Jobs
- `EmailCampaignSenderJob` - Send campaign emails in batches
- `EmailAutomationJob` - Process triggered automation emails
- `EmailTrackingJob` - Sync delivery/open/click events from provider
- `SegmentRefreshJob` - Update customer segments daily

---

## Email Automation Workflows

### 1. Quote Follow-Up Sequence
```
Trigger: Quote created, no booking within 24 hours
│
├─ Email 1 (24h later): "Still interested? Here's your quote"
│  └─ If no response after 3 days
│     ├─ Email 2 (72h later): "Need help deciding? FAQ + testimonials"
│        └─ If no response after 4 days
│           └─ Email 3 (7 days later): "Last chance! 10% off if you book today"
```

### 2. Past Customer Re-Engagement
```
Trigger: Customer hasn't booked in 90 days
│
├─ Email 1: "We miss you! Here's what's new"
│  └─ If opened but not clicked
│     └─ Email 2 (7 days later): "Special comeback offer: 15% off"
```

### 3. Post-Rental Review Request
```
Trigger: Booking completed
│
├─ Email 1 (2 days later): "How was your rental? Leave a review"
│  └─ If no review after 7 days
│     └─ Email 2: "Your feedback matters + chance to win $50 gift card"
```

### 4. Seasonal Campaign
```
Scheduled: 2 weeks before summer party season
│
├─ Segment: Customers who rented party equipment before
│  └─ Email: "Plan your summer party now - early bird 20% off"
```

---

## Email Template Variables (Personalization)

### Customer Variables
```liquid
{{ customer_name }}           # "John Doe"
{{ customer_email }}          # "john@example.com"
{{ customer_phone }}          # "555-0123"
{{ total_bookings }}          # 5
{{ last_booking_date }}       # "March 15, 2025"
{{ customer_since }}          # "January 2024"
```

### Booking Variables
```liquid
{{ booking_id }}              # "BK-1234"
{{ booking_total }}           # "$450.00"
{{ rental_dates }}            # "March 15-17, 2026"
{{ product_name }}            # "Excavator XL"
{{ pickup_location }}         # "123 Main St"
```

### Company Variables
```liquid
{{ company_name }}            # "ABC Rentals"
{{ company_phone }}           # "555-9999"
{{ company_logo_url }}        # "https://..."
{{ booking_url }}             # Link to create booking
```

### Example Template
```html
<p>Hi {{ customer_name }},</p>

<p>Thanks for your interest in renting our {{ product_name }}!</p>

<p>Your quote total is <strong>{{ quote_total }}</strong> for {{ rental_dates }}.</p>

<p>Ready to book? <a href="{{ booking_url }}">Click here to confirm</a></p>

<p>Questions? Reply to this email or call us at {{ company_phone }}.</p>

<p>Best,<br>{{ company_name }}</p>
```

---

## Email Provider Integration

### SendGrid API
```ruby
require 'sendgrid-ruby'
include SendGrid

mail = SendGrid::Mail.new
mail.from = Email.new(email: 'no-reply@rentable.com', name: 'Rentable')
mail.subject = 'Your Rental Quote'
mail.add_personalization(
  Personalization.new.tap do |p|
    p.add_to(Email.new(email: customer.email, name: customer.name))
    p.add_custom_arg(CustomArg.new(key: 'campaign_id', value: campaign.id.to_s))
  end
)
mail.add_content(Content.new(type: 'text/html', value: rendered_html))

# Tracking
mail.tracking_settings = TrackingSettings.new.tap do |t|
  t.click_tracking = ClickTracking.new(enable: true)
  t.open_tracking = OpenTracking.new(enable: true)
end

sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
response = sg.client.mail._('send').post(request_body: mail.to_json)
```

### Webhook for Tracking
```ruby
# POST /webhooks/sendgrid
def sendgrid_webhook
  events = params[:_json]

  events.each do |event|
    campaign_send = EmailCampaignSend.find_by(
      sendgrid_message_id: event['sg_message_id']
    )

    case event['event']
    when 'delivered'
      campaign_send.update(status: 'delivered', delivered_at: event['timestamp'])
    when 'open'
      campaign_send.update(status: 'opened', opened_at: event['timestamp'])
    when 'click'
      campaign_send.update(status: 'clicked', clicked_at: event['timestamp'])
    when 'bounce'
      campaign_send.update(status: 'bounced', bounced_at: event['timestamp'])
    end
  end
end
```

---

## Compliance (CAN-SPAM Act)

### Required Elements
- [ ] Clear "From" name and email address
- [ ] Accurate subject line (no deception)
- [ ] Physical mailing address in footer
- [ ] Clear unsubscribe link
- [ ] Process unsubscribe within 10 business days
- [ ] Don't email after unsubscribe

### Implementation
```ruby
class Customer < ApplicationRecord
  validates :email_opt_in, inclusion: { in: [true, false] }

  def can_receive_marketing_emails?
    email_opt_in && !email_bounced && !unsubscribed_at.present?
  end
end

# Unsubscribe link in every email
unsubscribe_url = "#{ENV['APP_URL']}/unsubscribe?token=#{customer.unsubscribe_token}"
```

---

## Dependencies

### Blocking
- Email service provider account (SendGrid/Postmark)
- Customer model with email_opt_in field (add if missing)

### Integration Points
- Booking system (trigger emails)
- Quote system (follow-up emails)
- Calendar (schedule campaigns)

---

## Risks & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Emails marked as spam | Medium | High | Warm up sender domain, double opt-in, clean lists |
| Email provider costs | Medium | Medium | Start with 10k/mo free tier, monitor usage |
| Unsubscribe rate too high | Medium | Medium | A/B test, segment properly, provide value |
| Template design complexity | Low | Medium | Start with simple templates, hire designer later |
| GDPR/privacy compliance | Medium | High | Consult legal, implement consent tracking |

---

## Email Service Provider Costs

### SendGrid Pricing
- **Free Tier**: 100 emails/day (3,000/month)
- **Essentials**: $15/mo - 50,000 emails
- **Pro**: $90/mo - 1,500,000 emails

### Postmark Pricing
- $10/month per 10,000 emails

**Estimated Monthly Cost**: $15-50 depending on volume

---

## Out of Scope

- Full marketing automation platform (Marketo-level) - Use dedicated tool
- Email list purchasing - We build organically
- GDPR full compliance system - Consult legal separately
- Advanced A/B testing (multivariate) - Phase 2
- Social media integration - Different epic

---

## Estimation

**Total Effort**: 12-18 days
- Backend: 8 days
- Frontend (template builder, dashboard): 6 days
- Testing: 4 days
- DevOps (email provider setup): 1 day

**Team Capacity**: 2 developers + 1 QA + 1 marketing SME (consulting)
**Target Completion**: End of Sprint 19

---

## Success Criteria

- [ ] Quote follow-up automation functional and tested
- [ ] Email template builder allows non-technical users to create templates
- [ ] Customer segmentation supports 5+ rule types
- [ ] Email tracking (open/click) working accurately
- [ ] Unsubscribe process compliant with CAN-SPAM
- [ ] Analytics dashboard shows key metrics
- [ ] A/B test shows 20% improvement in quote conversion
- [ ] 95% test coverage
- [ ] Successfully sent 1,000+ emails without deliverability issues

---

## Related Epics

- **CRM**: Customer relationship management (integration)
- **FORECAST**: Predict which customers likely to book (integration)
- **SMS**: Add SMS channel alongside email (related)

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| 2026-02-28 | Product Owner | Epic created |
