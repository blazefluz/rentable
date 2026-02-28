# Product Owner

Agile product ownership, backlog management, and stakeholder collaboration for Rentable.

## Description

This skill provides expert product ownership capabilities:
- Product backlog management
- User story writing and refinement
- Sprint planning and prioritization
- Stakeholder communication
- Acceptance criteria definition
- Value maximization
- Release planning
- Agile ceremonies facilitation

## When to Use

Use this skill when you need to:
- Write user stories with acceptance criteria
- Prioritize product backlog
- Plan sprint goals
- Define features and requirements
- Create release plans
- Analyze user feedback
- Make trade-off decisions
- Facilitate backlog refinement
- Define product metrics

## Core Responsibilities

### 1. Backlog Management
- Maintain prioritized product backlog
- Refine and estimate user stories
- Manage technical debt items
- Balance new features vs. improvements

### 2. Stakeholder Collaboration
- Gather requirements from customers
- Communicate product vision
- Manage expectations
- Demo completed features
- Collect and act on feedback

### 3. Value Maximization
- Prioritize based on business value
- Define success metrics
- Make data-driven decisions
- Balance short-term vs. long-term goals

## User Story Templates

### Epic Template
```markdown
# Epic: Advanced Booking Management

**As a** rental company manager
**I want** advanced booking management capabilities
**So that** I can efficiently manage my equipment rentals and maximize utilization

## Business Value
- Increase booking efficiency by 30%
- Reduce booking conflicts by 90%
- Improve customer satisfaction scores

## Success Metrics
- Average booking creation time < 2 minutes
- Booking conflict rate < 5%
- Customer satisfaction score > 4.5/5

## User Stories
1. Create recurring bookings
2. Booking templates for common rentals
3. Automated availability checking
4. Smart pricing recommendations
5. Bulk booking operations

## Dependencies
- Payment system integration
- Email notification system
- Calendar integration

## Acceptance Criteria (Epic Level)
- [ ] All user stories completed
- [ ] Success metrics achieved
- [ ] Customer acceptance received
- [ ] Documentation complete
```

### User Story Template
```markdown
# User Story: Create Recurring Bookings

**Story ID**: RB-123
**Epic**: Advanced Booking Management
**Sprint**: Sprint 15
**Priority**: High
**Story Points**: 8

## Story
**As a** rental company manager
**I want to** create recurring bookings that automatically generate at scheduled intervals
**So that** I don't have to manually create weekly/monthly bookings for regular customers

## Business Value
Regular customers (ABC Corp, XYZ Events) account for 40% of revenue.
Automating their bookings saves 5 hours/week of admin time and reduces errors.

## Acceptance Criteria
**Given** I am a logged-in manager
**When** I create a new recurring booking
**Then** I should be able to:
- [ ] Specify frequency (daily, weekly, monthly)
- [ ] Set start and end dates for the recurrence
- [ ] Define which products/kits to book
- [ ] Set customer details
- [ ] Preview the generated bookings before confirming

**Given** a recurring booking is active
**When** the scheduled time arrives
**Then** the system should:
- [ ] Automatically create the next booking
- [ ] Check availability before creating
- [ ] Send confirmation email to customer
- [ ] Notify me if availability issue occurs
- [ ] Update the next occurrence date

**Given** I want to modify a recurring booking
**When** I access the recurring booking settings
**Then** I should be able to:
- [ ] Pause/resume the recurrence
- [ ] Edit future occurrences
- [ ] Cancel the recurring pattern
- [ ] View all past and future occurrences

## Technical Notes
- Use RecurringBooking model (already exists)
- Implement background job: GenerateRecurringBookingsJob
- Check availability before creating each occurrence
- Handle edge cases (equipment unavailable, dates conflict)

## UI/UX Requirements
- Add "Create Recurring Booking" button on bookings page
- Modal with frequency selector and date pickers
- Preview panel showing next 5 occurrences
- Clear visual indication of recurring vs. regular bookings

## Definition of Done
- [ ] Code complete and peer reviewed
- [ ] Unit tests written (>80% coverage)
- [ ] Integration tests for booking creation
- [ ] API endpoints documented
- [ ] Manual testing completed
- [ ] Product Owner acceptance received
- [ ] Deployed to staging
- [ ] User documentation updated

## Dependencies
- RecurringBooking model (✅ Done)
- Background job infrastructure (✅ Done)
- Email notification system (✅ Done)

## Questions/Risks
- Q: What happens if a customer cancels mid-recurrence?
  A: Individual occurrences can be cancelled, pattern continues

- Q: How far in advance should bookings be created?
  A: Create bookings 2 weeks in advance

- Risk: Availability checking might be slow for long recurrences
  Mitigation: Limit recurrence to max 52 occurrences (1 year)
```

### Bug Fix Story Template
```markdown
# Bug: Booking Total Incorrect with Weekend Pricing

**Bug ID**: BUG-045
**Priority**: High
**Severity**: Major
**Reported By**: Customer Support
**Assigned To**: Backend Developer

## Problem Statement
**As a** rental company using weekend pricing
**I am experiencing** incorrect booking totals that don't reflect weekend rates
**This impacts** revenue accuracy and customer trust

## Expected Behavior
When creating a booking that spans weekend days:
- Saturday and Sunday should use `weekend_price`
- Other days should use `daily_price`
- Total should be: (weekend_days × weekend_price) + (weekday_days × daily_price)

## Actual Behavior
All days use `daily_price`, resulting in lower totals and revenue loss.

## Steps to Reproduce
1. Create product with daily_price: $100, weekend_price: $150
2. Create booking from Saturday to Monday (3 days)
3. Observe calculated total
4. **Expected**: (2 × $150) + (1 × $100) = $400
5. **Actual**: 3 × $100 = $300

## Impact
- **Business Impact**: Revenue loss of ~15% on weekend bookings
- **Affected Customers**: 3 major clients reported, likely affecting all
- **Frequency**: Every booking spanning weekends (est. 60% of bookings)

## Acceptance Criteria
- [ ] Weekend pricing correctly applied to Saturday/Sunday
- [ ] Weekday pricing correctly applied to other days
- [ ] Total calculation matches expected formula
- [ ] Existing bookings can be recalculated if needed
- [ ] Unit tests added for weekend pricing logic
- [ ] Regression test added to prevent recurrence

## Technical Investigation
File: `app/models/booking_line_item.rb`
Method: `calculate_dynamic_price`
Issue: Not checking day of week when calculating price

## Root Cause
The `calculate_dynamic_price` method uses `daily_price` for all days instead of checking `Date#saturday?` and `Date#sunday?` to apply weekend pricing.

## Definition of Done
- [ ] Fix implemented and deployed
- [ ] All existing tests passing
- [ ] New tests for weekend pricing
- [ ] Tested on staging
- [ ] Product Owner verified fix
- [ ] Customers notified of fix
```

## Sprint Planning

### Sprint Goal Template
```markdown
# Sprint 15 Goal

**Duration**: March 1-14, 2026 (2 weeks)
**Theme**: Booking Automation & Efficiency

## Sprint Goal
Enable recurring bookings and booking templates to reduce manual work for regular customers and improve operational efficiency.

## Why This Sprint?
- Regular customers requesting automated bookings
- Support team spending 5+ hours/week on manual recurring bookings
- Customer satisfaction score dipped due to booking errors

## Success Criteria
- [ ] Recurring bookings feature complete and deployed
- [ ] At least 3 customers using recurring bookings
- [ ] Support time for manual bookings reduced by 50%
- [ ] Zero critical bugs in production

## Committed Stories (32 points)
1. **RB-123**: Create Recurring Bookings (8 pts) - High Priority
2. **RB-124**: Booking Templates (5 pts) - High Priority
3. **RB-125**: Bulk Booking Import (8 pts) - Medium Priority
4. **BUG-045**: Fix Weekend Pricing Bug (5 pts) - High Priority
5. **RB-126**: Booking Calendar View (5 pts) - Medium Priority
6. **TECH-15**: API Performance Optimization (1 pt) - Tech Debt

## Stretch Goals (8 points)
- **RB-127**: Smart Pricing Suggestions (5 pts)
- **RB-128**: Booking Conflict Warnings (3 pts)

## Team Capacity
- Backend Developer: 16 points
- Frontend Developer: 16 points
- Total: 32 points

## Dependencies & Risks
- ✅ RecurringBooking model already implemented
- ✅ Background job infrastructure ready
- ⚠️ Frontend developer out March 8-9 (reduced by 2 days)
- ⚠️ Payment provider maintenance window March 12

## Sprint Ceremonies
- **Sprint Planning**: Monday, March 1, 9:00 AM
- **Daily Standup**: Every day, 9:30 AM
- **Backlog Refinement**: Wednesday, March 10, 2:00 PM
- **Sprint Review**: Friday, March 14, 2:00 PM
- **Sprint Retro**: Friday, March 14, 3:30 PM
```

## Release Planning

### Release Plan Template
```markdown
# Release 2.5.0 - Q1 2026 Major Release

**Release Date**: March 31, 2026
**Theme**: Automation & Efficiency
**Type**: Major Feature Release

## Release Goals
1. Reduce manual booking operations by 50%
2. Increase customer self-service capabilities
3. Improve booking accuracy and reduce conflicts
4. Enable enterprise-level automation features

## Features Included

### Epic 1: Advanced Booking Management (Completed)
- ✅ Recurring bookings
- ✅ Booking templates
- ✅ Bulk booking import
- ✅ Calendar view with availability

### Epic 2: Smart Pricing (In Progress - Sprint 16)
- 🔄 Dynamic pricing rules
- 🔄 Weekend/holiday pricing
- 🔄 Discount automation
- 📅 Pricing recommendations (Sprint 17)

### Epic 3: Customer Self-Service Portal (Sprint 17-18)
- 📅 Customer login and dashboard
- 📅 Self-service booking creation
- 📅 Order history and invoices
- 📅 Equipment catalog browsing

### Bug Fixes & Improvements
- ✅ Weekend pricing calculation fix
- ✅ API performance optimization (30% faster)
- ✅ Mobile responsive improvements
- ✅ Email notification improvements

## Success Metrics
| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| Manual booking time | 10 min/booking | 5 min/booking | 🎯 On Track |
| Booking conflicts | 12% | <5% | 🔄 In Progress |
| Customer satisfaction | 4.2/5 | 4.5/5 | 🎯 On Track |
| API response time | 450ms | <300ms | ✅ Achieved |

## Release Checklist
- [ ] All committed features complete
- [ ] All critical/high bugs fixed
- [ ] Performance targets met
- [ ] Security audit passed
- [ ] Documentation updated
- [ ] Customer communications sent
- [ ] Training materials prepared
- [ ] Rollback plan ready
- [ ] Monitoring and alerts configured
- [ ] Production deployment scheduled

## Rollout Plan
1. **March 24**: Deploy to staging
2. **March 25-27**: QA testing on staging
3. **March 28**: Customer beta testing (5 selected customers)
4. **March 29**: Final fixes and adjustments
5. **March 30**: Deploy to production (6 PM off-peak)
6. **March 31**: Monitor and announce release

## Communication Plan
- **March 20**: Blog post announcing upcoming features
- **March 25**: Email to beta testers
- **March 31**: Release notes published
- **April 1**: Customer webinar demonstrating new features
- **April 3**: Follow-up email with tutorial videos

## Risks & Mitigation
| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Payment integration issues | High | Low | Extra testing week, rollback plan |
| Performance degradation | Medium | Medium | Load testing, monitoring alerts |
| Customer adoption slow | Low | Medium | Training materials, support |
| Breaking changes in API | High | Low | Versioned API, deprecation notices |
```

## Prioritization Framework

### MoSCoW Method
```markdown
# Feature Prioritization: Q2 2026

## Must Have (Critical for Release)
1. **Equipment Maintenance Tracking**
   - Compliance requirement for insurance
   - Impact: Legal/Insurance
   - Effort: 2 sprints

2. **Multi-Currency Support**
   - Required for international expansion
   - Impact: Revenue (New markets)
   - Effort: 1 sprint

3. **Security Audit Fixes**
   - Critical vulnerabilities found
   - Impact: Security/Trust
   - Effort: 1 sprint

## Should Have (Important but not critical)
1. **Mobile App (iOS)**
   - Customer request #1
   - Impact: User Experience
   - Effort: 4 sprints

2. **Advanced Reporting Dashboard**
   - Requested by 60% of customers
   - Impact: Analytics/Insights
   - Effort: 2 sprints

3. **Integration with QuickBooks**
   - Accounting automation
   - Impact: Efficiency
   - Effort: 1 sprint

## Could Have (Nice to have)
1. **QR Code Equipment Tracking**
   - Operational efficiency
   - Impact: Operations
   - Effort: 1 sprint

2. **Customer Loyalty Program**
   - Retention strategy
   - Impact: Customer Lifetime Value
   - Effort: 2 sprints

## Won't Have (Not this quarter)
1. **AI-Powered Pricing**
   - Interesting but unproven ROI
   - Deferred to Q3

2. **Social Media Integration**
   - Low customer demand
   - Deferred to Q4
```

### RICE Scoring Example
```markdown
# RICE Prioritization: Feature Comparison

## Formula: (Reach × Impact × Confidence) / Effort = RICE Score

### Feature 1: Recurring Bookings
- **Reach**: 500 users/quarter (of 2000 total) = 25%
- **Impact**: Massive (3) - Saves 5 hours/week per user
- **Confidence**: 100% - Clear customer demand
- **Effort**: 2 person-weeks
- **Score**: (500 × 3 × 1.0) / 2 = **750**

### Feature 2: Mobile App
- **Reach**: 1200 users/quarter = 60%
- **Impact**: Large (2) - Improves convenience
- **Confidence**: 80% - Assuming adoption
- **Effort**: 8 person-weeks
- **Score**: (1200 × 2 × 0.8) / 8 = **240**

### Feature 3: AI Pricing
- **Reach**: 2000 users/quarter = 100%
- **Impact**: Medium (1) - Potential revenue increase
- **Confidence**: 50% - Unproven ROI
- **Effort**: 6 person-weeks
- **Score**: (2000 × 1 × 0.5) / 6 = **167**

### Priority Order
1. ✅ **Recurring Bookings** (Score: 750)
2. 🔄 **Mobile App** (Score: 240)
3. 📅 **AI Pricing** (Score: 167)
```

## Metrics & KPIs

### Product Metrics Dashboard
```markdown
# Rentable Product Metrics - Q1 2026

## Activation Metrics
- **Sign-ups**: 45 new companies (↑15% MoM)
- **Activation Rate**: 78% (first booking within 7 days)
- **Time to First Booking**: 2.3 days average
- **Onboarding Completion**: 82%

## Engagement Metrics
- **Daily Active Users (DAU)**: 432
- **Weekly Active Users (WAU)**: 1,234
- **Monthly Active Users (MAU)**: 2,156
- **DAU/MAU Ratio**: 20% (Sticky product)
- **Average Session Duration**: 12.5 minutes
- **Bookings per Active User**: 8.7/month

## Business Metrics
- **Monthly Recurring Revenue (MRR)**: $45,670
- **Average Revenue Per User (ARPU)**: $89/month
- **Customer Lifetime Value (LTV)**: $1,068
- **Customer Acquisition Cost (CAC)**: $245
- **LTV:CAC Ratio**: 4.4:1 (Healthy)
- **Churn Rate**: 3.2% (Low)

## Feature Adoption
- **Recurring Bookings**: 35% of active customers
- **Booking Templates**: 42% of active customers
- **API Usage**: 28% of professional+ tier
- **Mobile Access**: 64% of sessions

## Support Metrics
- **Support Tickets**: 87 (↓12% from last month)
- **Average Response Time**: 2.3 hours
- **Customer Satisfaction (CSAT)**: 4.6/5
- **Net Promoter Score (NPS)**: 68 (Promoters)

## Technical Metrics
- **API Uptime**: 99.97%
- **Average Response Time**: 285ms (↓35% from last month)
- **Error Rate**: 0.12%
- **Deployment Frequency**: 3.2 per week
```

## Stakeholder Communication

### Sprint Review Agenda
```markdown
# Sprint 15 Review - March 14, 2026

**Duration**: 60 minutes
**Attendees**: Product Owner, Dev Team, Stakeholders

## Agenda

### 1. Sprint Goal Recap (5 min)
- Review sprint goal: "Enable recurring bookings"
- Remind of committed stories

### 2. Demo of Completed Work (30 min)

#### Story 1: Recurring Bookings (8 pts) ✅
**Demo by**: Backend Developer
- Show creating a weekly recurring booking
- Show system auto-generating next occurrence
- Show email notification to customer
- Show calendar view with recurring bookings
**Business Value**: Saves 5 hours/week for regular customers

#### Story 2: Booking Templates (5 pts) ✅
**Demo by**: Frontend Developer
- Show creating a template from existing booking
- Show applying template to new booking
- Show managing template library
**Business Value**: Reduces booking creation time by 60%

#### Bug Fix: Weekend Pricing (5 pts) ✅
**Demo by**: Backend Developer
- Show booking calculation with weekend pricing
- Show before/after comparison
- Show unit test coverage
**Business Value**: Fixes revenue loss of $2,400/month

### 3. Sprint Metrics (10 min)
- **Velocity**: 32 points (committed) / 32 points (completed) = 100%
- **Quality**: 0 production bugs, 95% test coverage
- **Deployment**: 5 deployments to staging, 1 to production

### 4. Stakeholder Feedback (10 min)
- Questions from stakeholders
- Feature requests
- Clarifications

### 5. Next Sprint Preview (5 min)
- Sprint 16 goal: Smart Pricing & Discounts
- Top priorities for next sprint
