# Sprint 19: Calendar Integration & Email Automation

**Sprint Goal**: Sync bookings to external calendars and launch automated email campaigns

**Start Date**: March 31, 2026
**End Date**: April 13, 2026
**Sprint Duration**: 10 working days

---

## Sprint Capacity

| Team Member | Capacity (points) | Allocated | Remaining |
|-------------|-------------------|-----------|-----------|
| backend-developer | 20 | 18 | 2 |
| frontend-developer | 16 | 14 | 2 |
| qa-tester | 12 | 10 | 2 |
| devops-engineer | 10 | 6 | 4 |
| **TOTAL** | **58** | **48** | **10** |

---

## Sprint Backlog

### Epic 1: Calendar Integration (21 pts)

#### CAL-101: Google Calendar Two-Way Sync (13 pts)
- **Assignee**: backend-developer
- **Tasks**:
  - [ ] Set up Google OAuth 2.0
  - [ ] Create calendar_integrations table
  - [ ] Implement GoogleCalendarService
  - [ ] Sync booking to Google Calendar
  - [ ] Two-way sync (fetch external changes)
  - [ ] Handle token refresh

#### CAL-102: Customer Calendar Invites (5 pts)
- **Assignee**: backend-developer
- **Tasks**:
  - [ ] Generate .ics files
  - [ ] Email calendar invite to customer
  - [ ] Test with Gmail, Outlook, Apple Mail

#### CAL-103: Availability Calendar Display (3 pts)
- **Assignee**: frontend-developer
- **Tasks**:
  - [ ] Product availability calendar component
  - [ ] Show available/unavailable dates
  - [ ] Integrate with booking flow

---

### Epic 2: Email Marketing (27 pts)

#### EMAIL-101: Quote Follow-Up Automation (8 pts)
- **Assignee**: backend-developer
- **Tasks**:
  - [ ] Set up SendGrid account
  - [ ] Create email_campaigns, email_templates tables
  - [ ] Implement quote follow-up sequence (24h, 72h, 7 days)
  - [ ] EmailAutomationService
  - [ ] Track open/click events

#### EMAIL-102: Past Customer Re-Engagement (5 pts)
- **Assignee**: backend-developer
- **Tasks**:
  - [ ] Customer segment: no booking in 90 days
  - [ ] Re-engagement email template
  - [ ] Automated campaign trigger

#### EMAIL-103: Email Template Builder (8 pts)
- **Assignee**: frontend-developer
- **Tasks**:
  - [ ] Drag-and-drop email builder UI
  - [ ] Liquid template variables
  - [ ] Preview functionality
  - [ ] Save/load templates

#### EMAIL-104: Customer Segmentation (6 pts)
- **Assignee**: backend-developer + frontend-developer
- **Backend** (3 pts): Segmentation logic
- **Frontend** (3 pts): Segment builder UI

---

## Sprint Commitments

**Committed**: 48 points
**Focus**: Split evenly between calendar and email features

---

## Definition of Done

- [ ] Google Calendar sync working
- [ ] Customers receive .ics calendar invites
- [ ] Automated quote follow-up emails sent
- [ ] Email template builder functional
- [ ] Customer segmentation working
- [ ] >85% test coverage
- [ ] Deployed to staging

---

## Demo Plan (April 13)

1. Connect Google Calendar, show booking sync
2. Customer receives calendar invite
3. Create email template with builder
4. Set up quote follow-up automation
5. Segment customers and send campaign

---

## Dependencies

- Google Cloud Console project setup (OAuth)
- SendGrid account and API key
- Email domain verification (SPF, DKIM)

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| 2026-02-28 | Product Owner | Sprint 19 planned |
