# User Story: Google Calendar Two-Way Sync

**Story ID**: CAL-101
**Epic**: [CAL - Calendar Integrations](../epics/CAL-calendar-integrations.md)
**Status**: Ready
**Priority**: CRITICAL (P0)
**Points**: 13
**Sprint**: Sprint 19
**Assigned To**: backend-developer

---

## Story

**As a** Rental Manager
**I want to** sync my bookings to Google Calendar automatically
**So that** I can see my schedule without logging into the rental system

---

## Acceptance Criteria

- [ ] **Given** I have a Google account
      **When** I authorize Google Calendar integration
      **Then** My access token is securely stored and encrypted

- [ ] **Given** I have connected my Google Calendar
      **When** A new booking is created
      **Then** An event is automatically created in my Google Calendar within 5 minutes

- [ ] **Given** A booking event exists in my Google Calendar
      **When** The booking is updated (dates, customer, status)
      **Then** The calendar event is automatically updated to match

- [ ] **Given** A booking is cancelled
      **When** The cancellation is processed
      **Then** The calendar event is automatically deleted

- [ ] **Given** I modify a booking event in Google Calendar (change time)
      **When** The system syncs (every 15 minutes)
      **Then** I receive a notification about the conflict for manual resolution

- [ ] **Given** My Google access token expires
      **When** The system attempts to sync
      **Then** The token is automatically refreshed using the refresh token

---

## Technical Details

### Database Schema
```sql
CREATE TABLE calendar_integrations (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  company_id BIGINT NOT NULL REFERENCES companies(id),

  provider VARCHAR(50) NOT NULL CHECK (provider IN ('google', 'outlook', 'apple_calendar')),
  sync_direction VARCHAR(50) DEFAULT 'one_way_to_external',

  -- OAuth credentials (encrypted)
  access_token TEXT NOT NULL,
  refresh_token TEXT NOT NULL,
  token_expires_at TIMESTAMP,

  -- Calendar ID
  external_calendar_id VARCHAR(255),

  -- Status
  enabled BOOLEAN DEFAULT TRUE,
  last_synced_at TIMESTAMP,
  sync_status VARCHAR(50) DEFAULT 'active',

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE calendar_events (
  id BIGSERIAL PRIMARY KEY,
  calendar_integration_id BIGINT NOT NULL REFERENCES calendar_integrations(id),

  -- Polymorphic association
  eventable_type VARCHAR(100) NOT NULL,
  eventable_id BIGINT NOT NULL,

  -- External event ID from Google/Outlook
  external_event_id VARCHAR(255) NOT NULL,

  last_synced_at TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_calendar_events_eventable ON calendar_events(eventable_type, eventable_id);
CREATE INDEX idx_calendar_integrations_user ON calendar_integrations(user_id);
```

### Models
```ruby
class CalendarIntegration < ApplicationRecord
  belongs_to :user
  belongs_to :company
  has_many :calendar_events, dependent: :destroy

  enum provider: { google: 'google', outlook: 'outlook', apple_calendar: 'apple_calendar' }
  enum sync_direction: {
    one_way_to_external: 'one_way_to_external',
    one_way_from_external: 'one_way_from_external',
    two_way: 'two_way'
  }

  encrypts :access_token
  encrypts :refresh_token

  validates :provider, :access_token, presence: true

  scope :enabled, -> { where(enabled: true) }
  scope :needs_sync, -> { where('last_synced_at IS NULL OR last_synced_at < ?', 15.minutes.ago) }

  def token_expired?
    token_expires_at && token_expires_at < Time.current
  end

  def refresh_token!
    GoogleCalendarService.new(self).refresh_access_token
  end
end

class CalendarEvent < ApplicationRecord
  belongs_to :calendar_integration
  belongs_to :eventable, polymorphic: true

  validates :external_event_id, presence: true, uniqueness: { scope: :calendar_integration_id }
end
```

### Services
```ruby
class GoogleCalendarService
  def initialize(calendar_integration)
    @integration = calendar_integration
    @client = Google::Apis::CalendarV3::CalendarService.new
    @client.authorization = authorization
  end

  def create_event(booking)
    event = Google::Apis::CalendarV3::Event.new(
      summary: "Rental: #{booking.product.name}",
      description: booking_description(booking),
      start: { date_time: booking.start_date.to_datetime.rfc3339 },
      end: { date_time: booking.end_date.to_datetime.rfc3339 },
      color_id: color_for_status(booking.status),
      reminders: {
        use_default: false,
        overrides: [
          { method: 'email', minutes: 1440 },  # 1 day before
          { method: 'popup', minutes: 60 }     # 1 hour before
        ]
      }
    )

    result = @client.insert_event(@integration.external_calendar_id, event)

    CalendarEvent.create!(
      calendar_integration: @integration,
      eventable: booking,
      external_event_id: result.id
    )

    result
  rescue Google::Apis::AuthorizationError
    refresh_token_and_retry(:create_event, booking)
  end

  def update_event(booking)
    calendar_event = CalendarEvent.find_by(eventable: booking, calendar_integration: @integration)
    return unless calendar_event

    event = @client.get_event(@integration.external_calendar_id, calendar_event.external_event_id)
    event.summary = "Rental: #{booking.product.name}"
    event.description = booking_description(booking)
    event.start.date_time = booking.start_date.to_datetime.rfc3339
    event.end.date_time = booking.end_date.to_datetime.rfc3339
    event.color_id = color_for_status(booking.status)

    @client.update_event(@integration.external_calendar_id, event.id, event)
    calendar_event.touch(:last_synced_at)
  rescue Google::Apis::AuthorizationError
    refresh_token_and_retry(:update_event, booking)
  end

  def delete_event(booking)
    calendar_event = CalendarEvent.find_by(eventable: booking, calendar_integration: @integration)
    return unless calendar_event

    @client.delete_event(@integration.external_calendar_id, calendar_event.external_event_id)
    calendar_event.destroy
  rescue Google::Apis::NotFoundError
    # Already deleted externally
    calendar_event.destroy
  rescue Google::Apis::AuthorizationError
    refresh_token_and_retry(:delete_event, booking)
  end

  def fetch_changes
    # Two-way sync: fetch external changes
    events = @client.list_events(
      @integration.external_calendar_id,
      updated_min: @integration.last_synced_at&.iso8601 || 1.day.ago.iso8601
    )

    events.items.each do |event|
      handle_external_change(event)
    end

    @integration.update(last_synced_at: Time.current)
  end

  def refresh_access_token
    # OAuth token refresh
    response = HTTParty.post('https://oauth2.googleapis.com/token', body: {
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      refresh_token: @integration.refresh_token,
      grant_type: 'refresh_token'
    })

    if response.success?
      @integration.update!(
        access_token: response['access_token'],
        token_expires_at: response['expires_in'].seconds.from_now
      )
    else
      @integration.update(sync_status: 'auth_failed', enabled: false)
      raise 'Failed to refresh token'
    end
  end

  private

  def authorization
    Signet::OAuth2::Client.new(access_token: @integration.access_token)
  end

  def booking_description(booking)
    <<~DESC
      Rental Booking ##{booking.id}
      Customer: #{booking.customer.name}
      Phone: #{booking.customer.phone}
      Pickup: #{booking.pickup_location}
      Status: #{booking.status.titleize}
    DESC
  end

  def color_for_status(status)
    case status
    when 'confirmed' then '2'  # Green
    when 'pending' then '5'    # Yellow
    when 'cancelled' then '11' # Red
    else '1'                    # Blue
    end
  end

  def refresh_token_and_retry(method, *args)
    refresh_access_token
    send(method, *args)
  end

  def handle_external_change(event)
    # Find corresponding booking
    calendar_event = CalendarEvent.find_by(
      calendar_integration: @integration,
      external_event_id: event.id
    )

    return unless calendar_event

    booking = calendar_event.eventable
    # Notify user of conflict - don't auto-update booking
    ConflictNotificationJob.perform_later(booking.id, event)
  end
end
```

### Background Jobs
```ruby
class CalendarSyncJob < ApplicationJob
  queue_as :default

  def perform
    CalendarIntegration.enabled.needs_sync.find_each do |integration|
      case integration.provider
      when 'google'
        GoogleCalendarService.new(integration).fetch_changes
      when 'outlook'
        OutlookCalendarService.new(integration).fetch_changes
      end
    end
  end
end

# In config/sidekiq.yml
# :schedule:
#   calendar_sync:
#     cron: '*/15 * * * *'  # Every 15 minutes
#     class: CalendarSyncJob
```

### OAuth Flow Controller
```ruby
class Api::V1::CalendarIntegrationsController < ApplicationController
  def authorize_google
    redirect_to google_oauth_url
  end

  def google_callback
    token = exchange_code_for_token(params[:code])

    CalendarIntegration.create!(
      user: current_user,
      company: current_company,
      provider: :google,
      access_token: token['access_token'],
      refresh_token: token['refresh_token'],
      token_expires_at: token['expires_in'].seconds.from_now,
      external_calendar_id: 'primary'
    )

    redirect_to calendar_settings_path, notice: 'Google Calendar connected!'
  end

  private

  def google_oauth_url
    params = {
      client_id: ENV['GOOGLE_CLIENT_ID'],
      redirect_uri: google_callback_url,
      scope: 'https://www.googleapis.com/auth/calendar',
      response_type: 'code',
      access_type: 'offline',
      prompt: 'consent'
    }

    "https://accounts.google.com/o/oauth2/v2/auth?#{params.to_query}"
  end

  def exchange_code_for_token(code)
    HTTParty.post('https://oauth2.googleapis.com/token', body: {
      code: code,
      client_id: ENV['GOOGLE_CLIENT_ID'],
      client_secret: ENV['GOOGLE_CLIENT_SECRET'],
      redirect_uri: google_callback_url,
      grant_type: 'authorization_code'
    })
  end
end
```

---

## Tasks

### Backend Tasks (13 pts)
- [ ] Set up Google Cloud Console project and OAuth credentials (2h)
- [ ] Create calendar_integrations and calendar_events migrations (1h)
- [ ] Create CalendarIntegration and CalendarEvent models (2h)
- [ ] Implement GoogleCalendarService (8h)
- [ ] Create OAuth flow controller and routes (2h)
- [ ] Implement token refresh logic (2h)
- [ ] Create CalendarSyncJob (2h)
- [ ] Add callbacks to Booking model (sync on create/update/destroy) (2h)
- [ ] Write comprehensive tests (4h)
- [ ] Handle edge cases (token expiry, API errors) (2h)

### Testing Tasks (QA)
- [ ] Test OAuth flow (2h)
- [ ] Test event creation/update/deletion (2h)
- [ ] Test token refresh (1h)
- [ ] Test error handling (1h)

### DevOps Tasks
- [ ] Add Google OAuth credentials to environment (30min)
- [ ] Set up Sidekiq cron for sync job (30min)

**Total**: ~30 hours (~13 points)

---

## Dependencies

- **Blocking**: Google Cloud Console project, OAuth setup
- **Integrates with**: Booking model (existing)

---

## Definition of Done

- [ ] OAuth flow working for Google Calendar
- [ ] Bookings sync to calendar within 5 minutes
- [ ] Two-way sync detects external changes
- [ ] Token refresh working automatically
- [ ] Color-coded events by status
- [ ] >85% test coverage
- [ ] Successfully tested with 100+ bookings

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| 2026-02-28 | Product Owner | Story created |
