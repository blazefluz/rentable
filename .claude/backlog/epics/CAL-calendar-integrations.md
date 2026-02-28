# Epic: Calendar Integrations

**Epic ID**: CAL
**Status**: Backlog
**Priority**: CRITICAL
**Business Value**: HIGH
**Target Release**: Phase 1 - Q2 2026

---

## Overview

Integrate with external calendar systems (Google Calendar, Outlook, Apple Calendar) to sync rental bookings, maintenance schedules, and delivery routes. Enables rental companies to manage all schedules in their preferred calendar app and provides customers with booking confirmations in their calendars.

## Business Problem

Current pain points:
- Staff manually duplicate booking info into their personal calendars
- No visibility into schedules when away from desk
- Missed deliveries/pickups due to calendar conflicts
- Customers request calendar invites for pickup/return times
- Maintenance schedules not visible alongside bookings
- Double-booking issues when staff doesn't check system

## Success Metrics

- **Primary**: 80% of bookings automatically synced to staff calendars
- **Secondary**:
  - 50% reduction in missed deliveries/pickups
  - 90% customer satisfaction with calendar integration
  - Zero double-bookings due to calendar conflicts
  - <2 seconds to sync calendar events

## User Personas

1. **Rental Manager** - Needs to see all bookings in their work calendar
2. **Delivery Driver** - Syncs delivery schedule to mobile calendar
3. **Customer** - Receives rental booking in their personal calendar
4. **Maintenance Technician** - Maintenance tasks appear in calendar

---

## User Stories

### Must Have (P0)
- [ ] CAL-101: Google Calendar two-way sync (13 pts)
- [ ] CAL-102: Send booking confirmation calendar invites to customers (5 pts)
- [ ] CAL-103: Display availability calendar on booking page (8 pts)
- [ ] CAL-104: Sync maintenance schedules to technician calendars (5 pts)
- [ ] CAL-105: Block out unavailable dates (vacations, holidays) (5 pts)

### Should Have (P1)
- [ ] CAL-106: Outlook/Office 365 integration (8 pts)
- [ ] CAL-107: Apple Calendar (.ics) support (3 pts)
- [ ] CAL-108: Calendar color-coding by booking status (3 pts)
- [ ] CAL-109: Delivery route calendar for drivers (5 pts)
- [ ] CAL-110: Reminder notifications (1 day before, 1 hour before) (3 pts)

### Nice to Have (P2)
- [ ] CAL-111: CalDAV/iCal feed subscription (5 pts)
- [ ] CAL-112: Team calendar view (multiple staff calendars) (8 pts)
- [ ] CAL-113: Calendar widget for website embedding (5 pts)
- [ ] CAL-114: Sync to multiple calendars per user (3 pts)

**Total Story Points**: 79 pts (Must Have: 36 pts)

---

## Technical Architecture

### New Models
```ruby
class CalendarIntegration < ApplicationRecord
  belongs_to :user
  belongs_to :company

  enum provider: [:google, :outlook, :apple_calendar, :ical_feed]
  enum sync_direction: [:one_way_to_external, :one_way_from_external, :two_way]

  # OAuth credentials stored encrypted
  encrypts :access_token
  encrypts :refresh_token

  validates :provider, presence: true
end

class CalendarEvent < ApplicationRecord
  belongs_to :calendar_integration
  belongs_to :eventable, polymorphic: true # Booking, MaintenanceSchedule, Delivery

  validates :external_event_id, presence: true
  validates :last_synced_at, presence: true
end

class CalendarAvailability < ApplicationRecord
  belongs_to :product
  belongs_to :company

  # Manual blocks for holidays, maintenance, etc.
  validates :blocked_from, :blocked_until, presence: true
end
```

### New Tables
- `calendar_integrations` - User calendar connections
- `calendar_events` - Mapping between internal events and external calendar events
- `calendar_sync_logs` - Audit trail of sync operations
- `calendar_availability` - Manual availability overrides

### API Endpoints
```
# Calendar Integration Setup
GET    /api/v1/calendar_integrations                    # List user's integrations
POST   /api/v1/calendar_integrations/google/authorize   # OAuth flow
POST   /api/v1/calendar_integrations/outlook/authorize  # OAuth flow
DELETE /api/v1/calendar_integrations/:id                # Disconnect calendar

# Calendar Operations
POST   /api/v1/calendar_integrations/:id/sync           # Manual sync trigger
GET    /api/v1/calendar_integrations/:id/events         # List synced events
POST   /api/v1/calendar_integrations/:id/test           # Test connection

# Calendar Availability
GET    /api/v1/products/:id/calendar                    # Product availability calendar
POST   /api/v1/calendar_availability                    # Block dates manually
DELETE /api/v1/calendar_availability/:id                # Unblock dates

# Customer Calendar Invites
POST   /api/v1/bookings/:id/send_calendar_invite        # Send .ics to customer
```

### Services
```ruby
class GoogleCalendarService
  # Google Calendar API integration
  def initialize(calendar_integration)
  def create_event(booking)
  def update_event(booking)
  def delete_event(booking)
  def fetch_events(date_range)
end

class OutlookCalendarService
  # Microsoft Graph API integration
  def initialize(calendar_integration)
  def create_event(booking)
  def update_event(booking)
  def delete_event(booking)
end

class CalendarSyncService
  # Orchestrates calendar synchronization
  def sync_booking_to_calendars(booking)
  def sync_maintenance_to_calendars(maintenance)
  def handle_external_changes(calendar_integration)
end

class CalendarInviteService
  # Generate .ics files for customer invites
  def generate_ics(booking)
  def send_email_with_invite(booking, recipient)
end

class AvailabilityCalendarService
  # Calculate product availability
  def available_dates(product, date_range)
  def is_available?(product, start_date, end_date)
end
```

### Background Jobs
- `CalendarSyncJob` - Periodic sync (every 15 minutes)
- `CalendarEventCreateJob` - Push new events to calendars
- `CalendarEventUpdateJob` - Update changed events
- `CalendarReminderJob` - Send reminder notifications

---

## External API Integration

### Google Calendar API
```ruby
# OAuth 2.0 flow
scope: 'https://www.googleapis.com/auth/calendar'

# Create event
POST https://www.googleapis.com/calendar/v3/calendars/primary/events
{
  "summary": "Rental: Excavator XL",
  "description": "Rental booking #1234\nCustomer: John Doe\nPhone: 555-0123",
  "start": { "dateTime": "2026-03-15T09:00:00-07:00" },
  "end": { "dateTime": "2026-03-17T17:00:00-07:00" },
  "colorId": "2",  # Color-code by status
  "reminders": {
    "useDefault": false,
    "overrides": [
      { "method": "email", "minutes": 1440 },  # 1 day before
      { "method": "popup", "minutes": 60 }     # 1 hour before
    ]
  }
}
```

### Microsoft Graph API (Outlook)
```ruby
# OAuth 2.0 flow
scope: 'Calendars.ReadWrite'

# Create event
POST https://graph.microsoft.com/v1.0/me/events
{
  "subject": "Rental: Excavator XL",
  "body": {
    "contentType": "HTML",
    "content": "Rental booking #1234<br>Customer: John Doe"
  },
  "start": {
    "dateTime": "2026-03-15T09:00:00",
    "timeZone": "Pacific Standard Time"
  },
  "end": {
    "dateTime": "2026-03-17T17:00:00",
    "timeZone": "Pacific Standard Time"
  }
}
```

### ICS File Format (Apple Calendar)
```ruby
# Generated .ics file
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Rentable//Booking Calendar//EN
BEGIN:VEVENT
UID:booking-1234@rentable.com
DTSTAMP:20260315T120000Z
DTSTART:20260315T090000Z
DTEND:20260317T170000Z
SUMMARY:Rental: Excavator XL
DESCRIPTION:Pickup: March 15 at 9am\nReturn: March 17 at 5pm
LOCATION:123 Main St, City, ST 12345
STATUS:CONFIRMED
END:VEVENT
END:VCALENDAR
```

---

## Data Flow

### Booking Created → Calendar Sync
```
1. User creates booking
2. CalendarSyncService.sync_booking_to_calendars(booking)
3. Identify users with calendar integrations (assigned staff, customer)
4. For each integration:
   - GoogleCalendarService.create_event(booking)
   - Store external_event_id in calendar_events table
5. Customer receives email with .ics attachment
```

### Two-Way Sync (External Changes)
```
1. CalendarSyncJob runs every 15 minutes
2. Fetch changes from external calendar since last sync
3. For each changed event:
   - Find corresponding booking via calendar_events mapping
   - Update booking if event was modified externally
   - Notify staff of change
   - Log conflict if business rules violated
```

---

## Dependencies

### Blocking
- OAuth configuration (Google Cloud Console, Azure AD)
- Booking system (existing)

### Integration Points
- Email system (send .ics attachments)
- Notification system (calendar reminders)
- Maintenance scheduling (MAINT epic)
- Delivery routing (ROUTE epic)

---

## Risks & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| OAuth token expiration | High | Medium | Automatic token refresh, user notification |
| API rate limits | Medium | Medium | Implement exponential backoff, queue system |
| Calendar conflict resolution | High | Medium | Clear conflict resolution rules, user choice |
| Data sync delays | Medium | Low | Set expectations (15-min sync interval) |
| Privacy concerns (customer data) | Low | High | Encrypted storage, minimal data in calendar |

---

## Security & Privacy

- **OAuth Tokens**: Encrypted in database, never logged
- **Customer Data**: Minimal PII in calendar events (no CC, no full address)
- **Permissions**: Users can only sync their own calendars
- **Audit Trail**: All calendar operations logged
- **Disconnect**: Users can revoke access anytime

---

## Out of Scope

- Scheduling assistant (suggest optimal times) - Phase 2
- Group calendar booking (book multiple items at once) - Phase 2
- Calendar analytics (most booked times, etc.) - Phase 3
- Custom calendar views/layouts - Phase 3
- CalDAV server (host our own calendar) - Not planned

---

## Estimation

**Total Effort**: 12-18 days
- Backend: 8 days
- Frontend: 5 days
- Testing: 4 days
- DevOps: 1 day (OAuth config, secrets management)

**Team Capacity**: 2 developers + 1 QA
**Target Completion**: End of Sprint 18

---

## Success Criteria

- [ ] OAuth flow working for Google Calendar and Outlook
- [ ] Bookings automatically appear in staff calendars within 15 minutes
- [ ] Customers receive .ics calendar invite via email
- [ ] Two-way sync: external changes reflected in system
- [ ] Conflict detection and resolution
- [ ] Color-coded events by booking status
- [ ] Reminder notifications sent
- [ ] 95% test coverage
- [ ] Successfully tested with 100+ concurrent calendar syncs

---

## Related Epics

- **EMAIL**: Email notifications with calendar attachments
- **MAINT**: Maintenance schedule calendar sync
- **ROUTE**: Delivery route calendar for drivers
- **MOBILE**: Mobile calendar access

---

## User Documentation

### For Staff
- How to connect your Google/Outlook calendar
- Understanding calendar color codes
- Handling calendar conflicts

### For Customers
- How to add rental to your calendar
- Setting up reminders

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| 2026-02-28 | Product Owner | Epic created |
