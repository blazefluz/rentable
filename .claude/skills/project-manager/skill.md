# Project Manager

Comprehensive project management for Rentable development, including planning, execution, monitoring, and stakeholder communication.

## Description

This skill provides expert project management capabilities:
- Project planning and scheduling
- Resource allocation and management
- Risk identification and mitigation
- Timeline tracking and reporting
- Budget management
- Team coordination
- Stakeholder communication
- Agile/Waterfall hybrid approaches
- Change management
- Quality assurance oversight

## When to Use

Use this skill when you need to:
- Create project plans and timelines
- Allocate resources across teams
- Track project progress
- Manage project risks and issues
- Coordinate multiple workstreams
- Report to stakeholders
- Manage project budgets
- Facilitate project meetings
- Handle scope changes
- Ensure on-time delivery

## Core Responsibilities

### 1. Project Planning
- Define project scope and objectives
- Create work breakdown structure (WBS)
- Develop project timeline
- Identify dependencies
- Allocate resources

### 2. Execution & Monitoring
- Track progress against plan
- Manage project backlog
- Coordinate team activities
- Monitor risks and issues
- Ensure quality standards

### 3. Stakeholder Management
- Regular status reporting
- Manage expectations
- Facilitate decision-making
- Communication planning
- Conflict resolution

### 4. Resource Management
- Team capacity planning
- Skill gap identification
- Vendor management
- Budget tracking
- Time tracking oversight

## Project Planning Templates

### Project Charter Template
```markdown
# Project Charter: Rentable Q1 2026 Platform Upgrade

**Project Manager**: Sarah Johnson
**Sponsor**: CTO
**Start Date**: January 6, 2026
**Target End Date**: March 31, 2026
**Budget**: $120,000

## Executive Summary
Upgrade Rentable platform with advanced automation features including recurring bookings, smart pricing, and customer self-service portal to reduce manual operations by 50% and increase customer satisfaction.

## Business Case
- **Problem**: Manual booking operations taking 10+ hours/week
- **Opportunity**: Increase customer self-service from 20% to 60%
- **Expected ROI**: $180k annual savings in operational costs
- **Strategic Alignment**: Supports company goal of scaling to 1000+ customers

## Project Objectives
1. ✅ **SMART Goal 1**: Implement recurring bookings by Feb 14 with 90% automation
2. ✅ **SMART Goal 2**: Reduce booking creation time from 10min to 5min by Mar 15
3. ✅ **SMART Goal 3**: Launch customer portal with 100+ active users by Mar 31

## Success Criteria
- [ ] All planned features deployed to production
- [ ] Customer satisfaction score > 4.5/5
- [ ] Zero critical bugs in production for 2 weeks post-launch
- [ ] 50% reduction in support tickets related to bookings
- [ ] 60% of customers using self-service features

## Scope

### In Scope
- Recurring bookings functionality
- Booking templates and bulk operations
- Smart pricing engine (basic)
- Customer self-service portal (MVP)
- Weekend/holiday pricing
- Calendar view with availability
- Mobile responsive improvements

### Out of Scope
- AI-powered pricing (deferred to Q2)
- Mobile native apps (separate project)
- Third-party integrations (QuickBooks, etc.)
- Multi-language support

## Key Deliverables
1. **Epic 1**: Advanced Booking Management (Sprints 15-16)
2. **Epic 2**: Smart Pricing Engine (Sprints 16-17)
3. **Epic 3**: Customer Self-Service Portal (Sprints 17-18)
4. **Documentation**: User guides, API docs, training materials
5. **Testing**: Full QA coverage, load testing results

## Stakeholders
| Stakeholder | Role | Interest | Influence |
|------------|------|----------|-----------|
| CEO | Sponsor | High | High |
| CTO | Technical Owner | High | High |
| Product Owner | Requirements | High | Medium |
| Customer Success | User Adoption | High | Medium |
| Dev Team (6) | Execution | Medium | Medium |
| Key Customers (5) | Beta Testing | Medium | Low |

## Assumptions
- Team capacity remains stable (no attrition)
- No major scope changes mid-project
- Stripe API remains stable
- Third-party services (AWS, SendGrid) maintain SLA

## Constraints
- Fixed deadline (March 31 for Q1 results)
- Budget cap at $120k
- 6-person development team (cannot expand)
- Must maintain 99.5% uptime during rollout

## Risks (Top 5)
1. **Technical Complexity** - Smart pricing algorithms complex (High/Medium)
2. **Resource Availability** - Frontend dev planning vacation (Medium/High)
3. **Scope Creep** - Stakeholders requesting additions (Medium/High)
4. **Integration Issues** - Payment system dependencies (High/Low)
5. **Customer Adoption** - Users may not adopt self-service (Medium/Medium)

## Budget Breakdown
- Development Team (6 × 3 months): $90,000
- Cloud Infrastructure (AWS): $5,000
- Third-party Services (Stripe, SendGrid, etc.): $3,000
- QA/Testing Tools: $2,000
- Contingency (15%): $18,000
- **Total**: $120,000

## Approval
- [ ] CEO Signature: _________________ Date: _______
- [ ] CTO Signature: _________________ Date: _______
- [ ] CFO Signature: _________________ Date: _______
```

### Project Plan Template
```markdown
# Rentable Q1 2026 - Detailed Project Plan

**Last Updated**: February 28, 2026
**Status**: 🟢 On Track

## Timeline Overview

```
Jan 6 - Jan 17   Sprint 14   Planning & Setup
Jan 20 - Feb 2   Sprint 15   Recurring Bookings
Feb 3 - Feb 16   Sprint 16   Smart Pricing
Feb 17 - Mar 2   Sprint 17   Customer Portal (Part 1)
Mar 3 - Mar 16   Sprint 18   Customer Portal (Part 2)
Mar 17 - Mar 23  Sprint 19   Bug Fixes & Polish
Mar 24 - Mar 30  QA & Deployment
Mar 31           Launch!
```

## Work Breakdown Structure (WBS)

### 1.0 Project Initiation (Week 1)
- 1.1 Project kickoff meeting
- 1.2 Team onboarding
- 1.3 Environment setup
- 1.4 Sprint 0 planning
- **Duration**: 5 days | **Owner**: PM | **Status**: ✅ Complete

### 2.0 Epic 1: Advanced Booking Management
- 2.1 Recurring Bookings Feature (Sprint 15)
  - 2.1.1 Backend: RecurringBooking model
  - 2.1.2 Backend: Background job for generation
  - 2.1.3 Frontend: Recurring booking form
  - 2.1.4 Frontend: Calendar integration
  - 2.1.5 Testing: Unit + Integration tests
  - **Duration**: 10 days | **Owner**: Backend Dev | **Status**: ✅ Complete

- 2.2 Booking Templates (Sprint 15)
  - 2.2.1 Backend: BookingTemplate model
  - 2.2.2 Backend: Template application logic
  - 2.2.3 Frontend: Template library UI
  - 2.2.4 Testing: Template scenarios
  - **Duration**: 5 days | **Owner**: Fullstack Dev | **Status**: ✅ Complete

- 2.3 Calendar View (Sprint 15)
  - 2.3.1 Frontend: Calendar component
  - 2.3.2 Backend: Availability API optimization
  - 2.3.3 Testing: Calendar interactions
  - **Duration**: 5 days | **Owner**: Frontend Dev | **Status**: ✅ Complete

### 3.0 Epic 2: Smart Pricing Engine
- 3.1 Dynamic Pricing Rules (Sprint 16)
  - 3.1.1 Backend: PricingRule model
  - 3.1.2 Backend: Pricing calculation engine
  - 3.1.3 Frontend: Pricing rule management UI
  - 3.1.4 Testing: Pricing scenarios
  - **Duration**: 8 days | **Owner**: Backend Dev | **Status**: 🔄 In Progress

- 3.2 Weekend/Holiday Pricing (Sprint 16)
  - 3.2.1 Backend: Date-based pricing logic
  - 3.2.2 Backend: Holiday calendar
  - 3.2.3 Frontend: Pricing calendar UI
  - **Duration**: 5 days | **Owner**: Backend Dev | **Status**: 📅 Planned

- 3.3 Discount Automation (Sprint 17)
  - 3.3.1 Backend: Discount rules engine
  - 3.3.2 Frontend: Discount configuration
  - **Duration**: 3 days | **Owner**: Backend Dev | **Status**: 📅 Planned

### 4.0 Epic 3: Customer Self-Service Portal
- 4.1 Authentication & Login (Sprint 17)
  - 4.1.1 Backend: Customer user model
  - 4.1.2 Backend: JWT for customers
  - 4.1.3 Frontend: Login/register flow
  - **Duration**: 5 days | **Owner**: Fullstack Dev | **Status**: 📅 Planned

- 4.2 Customer Dashboard (Sprint 17)
  - 4.2.1 Frontend: Dashboard layout
  - 4.2.2 Backend: Customer data APIs
  - 4.2.3 Frontend: Booking history
  - **Duration**: 5 days | **Owner**: Frontend Dev | **Status**: 📅 Planned

- 4.3 Self-Service Booking (Sprint 18)
  - 4.3.1 Frontend: Product catalog
  - 4.3.2 Frontend: Booking creation flow
  - 4.3.3 Backend: Self-service validation
  - **Duration**: 8 days | **Owner**: Fullstack Dev | **Status**: 📅 Planned

- 4.4 Payment Integration (Sprint 18)
  - 4.4.1 Frontend: Stripe Elements
  - 4.4.2 Backend: Payment processing
  - 4.4.3 Testing: Payment scenarios
  - **Duration**: 5 days | **Owner**: Backend Dev | **Status**: 📅 Planned

### 5.0 Quality Assurance (Sprint 19)
- 5.1 Full regression testing
- 5.2 Performance/load testing
- 5.3 Security audit
- 5.4 UAT with beta customers
- **Duration**: 5 days | **Owner**: QA Lead | **Status**: 📅 Planned

### 6.0 Deployment & Launch (Week 13)
- 6.1 Staging deployment
- 6.2 Production deployment
- 6.3 Monitoring setup
- 6.4 Customer communication
- **Duration**: 7 days | **Owner**: DevOps | **Status**: 📅 Planned

## Dependencies

### Critical Path
```
Project Kickoff → Sprint 15 (Recurring) → Sprint 16 (Pricing) →
Sprint 17 (Portal Auth) → Sprint 18 (Self-Service) →
Sprint 19 (QA) → Production Launch
```

### External Dependencies
- ✅ Stripe API access (confirmed)
- ✅ SendGrid email service (active)
- ✅ AWS infrastructure (provisioned)
- ⚠️ Customer beta testers (5 confirmed, need 5 more)

### Internal Dependencies
- Sprint 18 depends on Sprint 17 (auth required)
- Smart pricing depends on recurring bookings (pricing rules apply to all bookings)
- QA sprint depends on all dev sprints completion

## Resource Allocation

### Team Assignments

**Backend Developer (2)**
- Primary: Recurring bookings, pricing engine, APIs
- Capacity: 16 pts/sprint
- Current Sprint: Sprint 16 (Pricing)

**Frontend Developer (2)**
- Primary: React components, customer portal
- Capacity: 16 pts/sprint
- Current Sprint: Sprint 16 (Pricing UI)

**Fullstack Developer (1)**
- Primary: Templates, portal integration
- Capacity: 14 pts/sprint
- Current Sprint: Sprint 16 (Holiday pricing)

**DevOps Engineer (1)**
- Primary: Infrastructure, CI/CD, monitoring
- Capacity: 10 pts/sprint (part-time on this project)
- Current Sprint: Performance optimization

**QA Engineer (1)**
- Primary: Testing strategy, automation
- Capacity: 12 pts/sprint
- Current Sprint: Test automation for Sprint 15 features

### Capacity Planning

| Sprint | Total Points | Available Capacity | Utilization |
|--------|-------------|-------------------|-------------|
| 14 | 28 | 32 | 88% |
| 15 | 32 | 32 | 100% |
| 16 | 30 | 32 | 94% |
| 17 | 28 | 30 | 93% (reduced capacity) |
| 18 | 32 | 32 | 100% |
| 19 | 12 | 32 | 38% (QA focus) |

**Note**: Sprint 17 reduced capacity due to frontend developer vacation (2 days)

## Risk Register

| ID | Risk | Impact | Probability | Mitigation | Owner | Status |
|----|------|--------|------------|------------|-------|--------|
| R1 | Pricing algorithm complexity exceeds estimates | High | Medium | Add 1 sprint buffer, simplify MVP | Backend Lead | 🟡 Monitor |
| R2 | Frontend dev vacation delays portal | Medium | High | Cross-train backend dev on React | PM | 🟢 Mitigated |
| R3 | Payment integration issues | High | Low | Early testing in Sprint 16 | Backend Dev | 🟢 Low Risk |
| R4 | Scope creep from stakeholders | Medium | High | Change control process enforced | PM | 🟡 Monitor |
| R5 | Performance degradation | High | Medium | Load testing in Sprint 19 | DevOps | 🟢 Planned |
| R6 | Customer adoption below target | Medium | Medium | Training materials + webinars | Customer Success | 🟢 Planned |
| R7 | API breaking changes | High | Low | Versioned APIs, deprecation notices | Tech Lead | 🟢 Low Risk |
| R8 | Team burnout from aggressive timeline | Medium | Medium | No overtime, sustainable pace | PM | 🟢 Monitor |

## Issues Log

| ID | Issue | Severity | Raised | Owner | Status | Resolution |
|----|-------|----------|--------|-------|--------|------------|
| I1 | Stripe webhook intermittent failures | Medium | Jan 15 | Backend | ✅ Resolved | Implemented retry logic |
| I2 | Calendar UI slow with 100+ bookings | Low | Feb 1 | Frontend | 🔄 In Progress | Adding pagination |
| I3 | Test environment unstable | Medium | Feb 10 | DevOps | ✅ Resolved | Increased database resources |
| I4 | Recurring job not running on schedule | High | Feb 12 | Backend | ✅ Resolved | Fixed Sidekiq cron config |

## Change Log

| Date | Change | Requestor | Impact | Approved | Status |
|------|--------|-----------|--------|----------|--------|
| Jan 20 | Add booking templates to Sprint 15 | Product Owner | +5 pts | Yes | ✅ Completed |
| Feb 5 | Defer AI pricing to Q2 | CTO | -8 pts | Yes | ✅ Descoped |
| Feb 18 | Add holiday calendar to pricing | Customer Success | +3 pts | Yes | 🔄 In Progress |

## Milestones

- ✅ **M1**: Project kickoff complete (Jan 6)
- ✅ **M2**: Recurring bookings live (Feb 2)
- 🔄 **M3**: Smart pricing deployed (Feb 16) - In Progress
- 📅 **M4**: Customer portal beta (Mar 2)
- 📅 **M5**: QA complete, ready for production (Mar 23)
- 📅 **M6**: Production launch (Mar 31)

## Status Dashboard

**Overall Project Health**: 🟢 On Track

**Schedule**: 🟢 On Track (Sprint 16 of 19)
**Budget**: 🟢 On Track ($72k of $120k spent, 60% complete)
**Scope**: 🟢 Stable (1 minor addition approved)
**Quality**: 🟢 Good (0 critical bugs, 95% test coverage)
**Team Morale**: 🟢 High (recent team survey: 4.3/5)
```

### Status Report Template
```markdown
# Weekly Status Report - Week of February 24, 2026

**Project**: Rentable Q1 Platform Upgrade
**Project Manager**: Sarah Johnson
**Reporting Period**: Feb 24 - Feb 28, 2026

## Executive Summary

✅ **Overall Status**: ON TRACK
📊 **Progress**: 60% complete (Sprint 16 of 19)
💰 **Budget**: $72,000 spent of $120,000 (60% - aligned with progress)
📅 **Schedule**: On target for March 31 launch

**Key Highlight**: Smart pricing engine core functionality completed this week. Team velocity strong at 30 points (target: 32).

## Accomplishments This Week

### Sprint 16: Smart Pricing (Day 8 of 10)

✅ **Completed**:
1. Dynamic pricing rules engine (8 pts)
   - PricingRule model with 5 rule types
   - Automatic calculation on booking creation
   - 95% test coverage

2. Weekend pricing implementation (5 pts)
   - Saturday/Sunday premium rates
   - Booking totals correctly calculate mixed weekday/weekend
   - Bug fix: Line item tax calculation corrected

3. API performance optimization (3 pts)
   - Product availability endpoint 40% faster
   - Database query optimization (N+1 eliminated)

🔄 **In Progress**:
4. Holiday pricing calendar (3 pts)
   - Backend: 80% complete
   - Frontend: Starting Monday

5. Discount automation (5 pts)
   - Planning phase, starts Monday

**Total Velocity**: 16 points completed, 8 points in progress

## Metrics

### Delivery Metrics
- **Story Points Completed**: 16 (vs 16 target)
- **Burndown**: On track, 8 points remaining in sprint
- **Velocity (last 3 sprints)**: 32, 32, 30 (avg: 31.3)
- **Defect Rate**: 0 critical, 2 minor bugs fixed
- **Test Coverage**: 95% (target: >90%)
- **Code Review Turnaround**: 4.2 hours avg

### Budget Metrics
- **Planned Budget**: $120,000
- **Actual Spend**: $72,000 (60%)
- **Forecast at Completion**: $118,500 (under budget)
- **Variance**: +$1,500 (favorable)

### Team Metrics
- **Team Capacity Utilization**: 94% (healthy)
- **Average Hours/Week**: 38 (sustainable)
- **Team Satisfaction**: 4.3/5 (recent survey)

## Risks & Issues

### New Risks
None this week.

### Existing Risks - Status Update

| Risk | Status | Update |
|------|--------|--------|
| R1: Pricing complexity | 🟢 LOW | Core engine done, complexity manageable |
| R2: Frontend dev vacation | 🟢 MITIGATED | Backup dev trained, schedule adjusted |
| R4: Scope creep | 🟡 MONITOR | 1 small addition approved (holiday calendar) |

### Issues This Week

✅ **Resolved**:
- I4: Recurring booking job not running → Fixed Sidekiq cron configuration

🔄 **Active**:
- I2: Calendar UI slow with 100+ bookings → 60% complete, adding pagination

## Upcoming Week (Mar 3 - Mar 7)

### Sprint 17: Customer Portal Part 1

**Goals**:
1. Complete Sprint 16 (holiday pricing, discount automation)
2. Sprint 17 Planning (Monday, Mar 3)
3. Start customer authentication implementation
4. Begin customer dashboard design

**Key Deliverables**:
- [ ] Holiday calendar fully functional
- [ ] Discount rules engine deployed
- [ ] Sprint 16 demo to stakeholders (Friday)
- [ ] Sprint 17 kickoff

**Team Availability**:
- Full team available (6 developers)
- No planned time off

## Decisions Needed

1. **Beta Customer Selection**: Need 5 more beta testers for customer portal (deadline: Mar 10)
   - Recommendation: Invite top 10 customers by revenue

2. **Self-Service Payment Flow**: Require payment upfront or allow invoicing?
   - Options: A) Payment required, B) Invoice option for established customers
   - Impact: Medium (affects Sprint 18 scope)
   - Needed by: Mar 3

## Blockers

None.

## Stakeholder Actions Required

- [ ] **CEO**: Approve beta customer list (by Mar 5)
- [ ] **Product Owner**: Review holiday calendar design (by Feb 29)
- [ ] **Customer Success**: Provide customer contact list for beta (by Mar 3)

## Attachments

- Sprint 16 Burndown Chart
- Test Coverage Report
- Budget Tracking Spreadsheet

---

**Next Report**: March 7, 2026
```

## Project Monitoring & Control

### Daily Standup Template
```markdown
# Daily Standup - February 28, 2026

**Time**: 9:30 AM
**Duration**: 15 minutes max
**Format**: Virtual (Zoom)

## Round Robin (2 min each)

### Backend Developer 1
**Yesterday**:
- Completed pricing rule calculation engine
- Fixed weekend pricing bug in BookingLineItem

**Today**:
- Start holiday calendar implementation
- Code review for discount automation PR

**Blockers**:
- None

---

### Frontend Developer 1
**Yesterday**:
- Implemented pricing rule management UI
- Added calendar component pagination

**Today**:
- Holiday calendar UI
- Sprint 16 demo prep

**Blockers**:
- Need design mockup for holiday calendar (assigned to Product Owner)

---

### DevOps Engineer
**Yesterday**:
- Optimized database queries (40% faster availability endpoint)
- Staging environment health check

**Today**:
- Set up load testing for Sprint 19
- Monitor production performance

**Blockers**:
- None

---

## Parking Lot (discuss after standup)
- Calendar pagination approach (Frontend Dev + Backend Dev)
- Holiday calendar data source (Product Owner input needed)

## Action Items
- [ ] Product Owner: Share holiday calendar mockup by 2 PM
- [ ] PM: Schedule Sprint 16 demo (Friday 2 PM)
```

### Sprint Retrospective Template
```markdown
# Sprint 15 Retrospective - February 14, 2026

**Participants**: Dev Team (6), Product Owner, Scrum Master
**Duration**: 90 minutes
**Format**: Start-Stop-Continue

## What Went Well ✅

1. **Velocity**: Hit 32/32 points (100% commitment)
   - Team: "Estimation getting better"

2. **Recurring Bookings**: Smooth implementation
   - Backend Dev: "Clear requirements made this easy"

3. **Code Quality**: 95% test coverage maintained
   - QA: "Testing mindset improving across team"

4. **Collaboration**: Backend/Frontend pairing effective
   - Frontend Dev: "Pairing on API integration saved 2 days"

## What Didn't Go Well ❌

1. **Bug in Weekend Pricing**: Found after merge
   - Impact: Delayed Sprint 15 completion by 1 day
   - Root cause: Insufficient edge case testing

2. **Calendar Performance**: Slow with 100+ bookings
   - Impact: User experience degraded
   - Root cause: Didn't consider scale during design

3. **Communication Gap**: Requirements unclear on templates
   - Impact: 3 hours of rework
   - Root cause: Product Owner not available for questions

## Action Items 🎯

| Action | Owner | Deadline |
|--------|-------|----------|
| Add weekend pricing regression test | Backend Dev | Feb 16 |
| Implement calendar pagination | Frontend Dev | Feb 18 |
| Product Owner office hours 2x/week | Product Owner | Starting Feb 17 |
| Performance testing earlier in sprint | QA Lead | Sprint 16 onward |
| Code review checklist update (edge cases) | Tech Lead | Feb 16 |

## Start Doing 🟢
- Performance testing mid-sprint (not just at end)
- Pair programming for complex features
- Product Owner available for real-time questions

## Stop Doing 🔴
- Merging PRs without 2 approvals
- Skipping edge case testing
- Assuming scale won't matter

## Continue Doing 🔵
- Daily standups (concise and valuable)
- Thorough code reviews
- Celebrating wins (team shoutouts)
- Retrospective action item tracking

## Team Shoutouts 🎉
- 🏆 Backend Dev 1: "Amazing debugging on recurring job issue"
- 🏆 Frontend Dev 2: "Calendar component looks fantastic"
- 🏆 QA Lead: "Caught 3 critical bugs before production"

## Happiness Metric
Team rated this sprint: **4.2/5** (up from 4.0 last sprint)

## Next Retro
- Date: February 28, 2026 (end of Sprint 16)
- Focus: Review action items from this retro
```

## Agile Ceremonies

### Sprint Planning Agenda
```markdown
# Sprint 16 Planning - February 3, 2026

**Duration**: 2 hours
**Attendees**: Dev Team, Product Owner, Scrum Master

## Part 1: Sprint Goal & Capacity (30 min)

### Sprint Goal
**"Implement smart pricing engine to enable weekend/holiday rates and automated discounts"**

**Why this sprint?**
- Customer revenue loss from manual weekend pricing
- 15% revenue increase potential with automated pricing
- Foundation for Q2 dynamic pricing features

### Team Capacity
- Backend Dev 1: 16 pts (100% available)
- Backend Dev 2: 16 pts (100% available)
- Frontend Dev 1: 16 pts (100% available)
- Frontend Dev 2: 16 pts (100% available)
- Fullstack Dev: 14 pts (1 day training)
- DevOps: 10 pts (part-time)
- **Total**: 88 pts available

**Commitments**: 30 pts planned (34% utilization - allows for unknowns)

## Part 2: Story Review & Estimation (60 min)

### High Priority Stories

**PRICE-101: Dynamic Pricing Rules Engine** (8 pts)
- As a rental manager, I want to create pricing rules based on duration, dates, and customer type
- Acceptance Criteria:
  - [ ] PricingRule model with 5 rule types
  - [ ] Automatic calculation on booking creation
  - [ ] Override capability
  - [ ] API endpoints for rule management
- Dependencies: None
- **Team Decision**: COMMIT

**PRICE-102: Weekend/Holiday Pricing** (5 pts)
- As a rental manager, I want Saturday/Sunday to use premium pricing
- Acceptance Criteria:
  - [ ] Product has weekend_price field
  - [ ] Booking calculation checks day of week
  - [ ] Holiday calendar integration
  - [ ] Visual indicator in UI
- Dependencies: PRICE-101
- **Team Decision**: COMMIT

**PRICE-103: Discount Automation** (5 pts)
- As a rental manager, I want to automatically apply discounts for long rentals
- Dependencies: PRICE-101
- **Team Decision**: COMMIT

**BUG-045: Line Item Tax Calculation** (5 pts)
- Fix: Tax not calculating correctly with weekend pricing
- **Team Decision**: COMMIT (HIGH PRIORITY)

**PRICE-104: Pricing Calendar UI** (5 pts)
- As a rental manager, I want to visualize pricing by date
- **Team Decision**: STRETCH GOAL

**TECH-08: API Performance Optimization** (2 pts)
- Optimize availability endpoint queries
- **Team Decision**: COMMIT

### Backlog Refinement Notes
- PRICE-105 (Pricing Analytics) - needs more detail, defer to Sprint 17
- PRICE-106 (Customer-specific pricing) - defer to Sprint 17

## Part 3: Task Breakdown (30 min)

**PRICE-101 Tasks**:
1. Create PricingRule model and migration (2 hrs)
2. Implement rule types (percentage, flat, tiered) (4 hrs)
3. Build calculation engine (6 hrs)
4. Create API endpoints (3 hrs)
5. Write unit tests (3 hrs)
6. Integration tests (2 hrs)

**Assigned to**: Backend Dev 1 (lead), Backend Dev 2 (support)

**PRICE-102 Tasks**:
1. Add weekend_price to Product (1 hr)
2. Update booking calculation logic (3 hrs)
3. Holiday calendar integration (4 hrs)
4. UI updates (4 hrs)
5. Tests (3 hrs)

**Assigned to**: Fullstack Dev

## Sprint Commitment

**Committed**: 30 points
1. PRICE-101 (8 pts)
2. PRICE-102 (5 pts)
3. PRICE-103 (5 pts)
4. BUG-045 (5 pts)
5. TECH-08 (2 pts)
6. Carry-over from Sprint 15: Documentation (5 pts)

**Stretch**: 5 points
- PRICE-104 (5 pts)

## Definition of Done Review
- [ ] Code complete and peer reviewed
- [ ] Unit tests (>90% coverage)
- [ ] Integration tests
- [ ] Manual QA testing
- [ ] Documentation updated
- [ ] Deployed to staging
- [ ] Product Owner acceptance

## Risks Identified
1. Pricing rule complexity may exceed estimate
2. Holiday calendar data source unclear
3. Tax calculation fix may have broader impact

**Mitigation**: Add 2-day buffer at end of sprint
```

## Communication Management

### Stakeholder Communication Plan
```markdown
# Stakeholder Communication Plan - Q1 2026 Project

## Stakeholder Matrix

| Stakeholder | Interest | Influence | Communication Need | Frequency |
|------------|----------|-----------|-------------------|-----------|
| CEO | High | High | Strategic updates, ROI | Bi-weekly |
| CTO | High | High | Technical decisions, risks | Weekly |
| Product Owner | High | Medium | Daily collaboration | Daily |
| Customer Success | High | Medium | Feature updates, training | Weekly |
| Finance | Medium | Medium | Budget tracking | Monthly |
| Key Customers | Medium | Low | Beta testing, feedback | As needed |
| Dev Team | High | Medium | Sprint planning, blockers | Daily |

## Communication Methods

### Executive Steering Committee
- **Who**: CEO, CTO, CFO, Product Owner, PM
- **Frequency**: Bi-weekly (Tuesdays, 10 AM)
- **Format**: 30-minute meeting + slide deck
- **Content**:
  - Project health dashboard
  - Milestone progress
  - Budget vs. actual
  - Key decisions needed
  - Top 3 risks

### Weekly Status Report
- **Who**: All stakeholders
- **Frequency**: Every Friday by 5 PM
- **Format**: Email + shared doc
- **Content**:
  - Executive summary (traffic light)
  - Accomplishments this week
  - Upcoming week plan
  - Risks and issues
  - Decisions needed

### Sprint Reviews
- **Who**: Product Owner, Dev Team, Customer Success, key stakeholders
- **Frequency**: Every 2 weeks (end of sprint)
- **Format**: 60-minute demo + Q&A
- **Content**:
  - Live demo of completed features
  - Sprint metrics
  - Next sprint preview
  - Stakeholder feedback

### Daily Standups
- **Who**: Dev Team, Scrum Master
- **Frequency**: Daily 9:30 AM
- **Format**: 15-minute standup (virtual)
- **Content**:
  - Yesterday, today, blockers
  - Parking lot items

### Ad-Hoc Communications

**Critical Issues**: Immediate
- Slack alert to #project-critical
- PM notifies CEO/CTO within 1 hour
- Post-mortem within 24 hours

**Scope Changes**: As needed
- Email request with impact analysis
- Steering Committee approval required
- Documented in change log

**Customer Feedback**: Weekly digest
- Compiled by Customer Success
- Shared in Friday status report
- Prioritized by Product Owner

## Templates

### Executive Dashboard (Bi-weekly)
```
🎯 Q1 Platform Upgrade - Executive Update
Date: February 28, 2026

OVERALL STATUS: 🟢 ON TRACK

Progress:     60% (Sprint 16/19)     ████████░░ 60%
Schedule:     🟢 Mar 31 on track
Budget:       🟢 $72k/$120k (60%)
Quality:      🟢 95% test coverage, 0 critical bugs
Team Health:  🟢 4.3/5 satisfaction

MILESTONES:
✅ Recurring Bookings (Feb 2)
🔄 Smart Pricing (Feb 16) - In Progress
📅 Customer Portal Beta (Mar 2)
📅 Production Launch (Mar 31)

TOP WINS:
• Recurring bookings live, 15 customers using
• API performance improved 40%
• Weekend pricing implemented, revenue impact: +$2,400/month

TOP RISKS:
• Scope creep potential (MEDIUM) - Change control enforced
• Team capacity Sprint 17 (LOW) - Mitigated with backup dev

DECISIONS NEEDED:
1. Approve beta customer list (CEO) - by Mar 5
2. Self-service payment flow (Product Owner) - by Mar 3

BUDGET: Under budget by $1,500 (favorable variance)
```

### Stakeholder Email Template
```
Subject: Rentable Q1 Upgrade - Week of Feb 24 Update

Hi Team,

Quick update on the Q1 Platform Upgrade project:

✅ ON TRACK for March 31 launch

This Week's Highlights:
• Smart pricing engine core completed (Sprint 16)
• Weekend pricing now calculating correctly
• API performance improved 40%

Next Week:
• Complete Sprint 16 (holiday calendar, discounts)
• Sprint 17 kickoff: Customer Portal authentication

Action Required:
• CEO: Review beta customer list by Mar 5
• Product Owner: Approve holiday calendar design by Feb 29

Full status report: [link to shared doc]

Questions? Reply or ping me on Slack.

Thanks,
Sarah (Project Manager)
```
```

## Budget & Resource Management

### Budget Tracking Template
```markdown
# Project Budget Tracking - Q1 2026

**Total Budget**: $120,000
**Spent to Date**: $72,000 (60%)
**Forecast at Completion**: $118,500
**Variance**: +$1,500 (under budget)

## Budget Breakdown

| Category | Planned | Actual | Remaining | Variance | Status |
|----------|---------|--------|-----------|----------|--------|
| Development Labor | $90,000 | $54,000 | $36,000 | $0 | 🟢 On Track |
| Cloud Infrastructure | $5,000 | $3,200 | $1,800 | +$200 | 🟢 Under |
| Third-party Services | $3,000 | $1,900 | $1,100 | +$100 | 🟢 Under |
| QA/Testing Tools | $2,000 | $800 | $1,200 | +$200 | 🟢 Under |
| Contingency (15%) | $18,000 | $12,100 | $5,900 | +$1,000 | 🟢 Available |
| **TOTAL** | **$120,000** | **$72,000** | **$48,000** | **+$1,500** | **🟢 Healthy** |

## Monthly Burn Rate

| Month | Planned | Actual | Variance |
|-------|---------|--------|----------|
| January | $32,000 | $31,500 | +$500 |
| February | $40,000 | $40,500 | -$500 |
| March (Projected) | $48,000 | $46,500 | +$1,500 |

## Cost Drivers

**Labor Costs** (60% of budget):
- 6 developers × 3 months × $5,000/month = $90,000
- Actual: On track (no overtime required)

**Infrastructure** (4% of budget):
- AWS: $1,500/month planned, $1,100 actual (optimized)
- Savings from PostgreSQL RDS optimization

**Services** (2.5% of budget):
- Stripe: $600 (transaction fees lower than expected)
- SendGrid: $400 (email volume lower)
- Monitoring tools: $900

## Forecast

**Projected Final Cost**: $118,500
- Development: On track
- Infrastructure: $1,000 savings
- Services: $500 savings
- Contingency usage: $12,100 (67% of contingency)

**Confidence Level**: HIGH (95%)

## Action Items
- Monitor contingency usage (currently healthy)
- Track overtime (none so far - good)
- Review vendor invoices monthly
```

### Resource Utilization Dashboard
```markdown
# Resource Utilization - Sprint 16

## Team Capacity Overview

| Resource | Role | Capacity | Allocated | Utilization | Available |
|----------|------|----------|-----------|-------------|-----------|
| Dev 1 | Backend | 80 hrs | 76 hrs | 95% | 4 hrs |
| Dev 2 | Backend | 80 hrs | 72 hrs | 90% | 8 hrs |
| Dev 3 | Frontend | 80 hrs | 78 hrs | 98% | 2 hrs |
| Dev 4 | Frontend | 80 hrs | 70 hrs | 88% | 10 hrs |
| Dev 5 | Fullstack | 80 hrs | 68 hrs | 85% | 12 hrs |
| Dev 6 | DevOps | 40 hrs | 38 hrs | 95% | 2 hrs |

**Total Capacity**: 440 hours
**Total Allocated**: 402 hours
**Overall Utilization**: 91% (target: 85-95%)

## Skills Matrix

| Developer | Backend | Frontend | DevOps | Database | Testing |
|-----------|---------|----------|--------|----------|---------|
| Dev 1 | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| Dev 2 | ⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| Dev 3 | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐ | ⭐ | ⭐⭐⭐ |
| Dev 4 | ⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐ | ⭐⭐⭐ |
| Dev 5 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| Dev 6 | ⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

## Workload Heatmap (Next 4 Weeks)

```
         Week 1    Week 2    Week 3    Week 4
Dev 1    ████████  ████████  ████░░░░  ████████
Dev 2    ████████  ████████  ████████  ████░░░░
Dev 3    ████████  ████████  ████████  ████████
Dev 4    ████████  ████░░░░  ████████  ████████
Dev 5    ████░░░░  ████████  ████████  ████████
Dev 6    ████░░░░  ████░░░░  ████████  ████████

Legend: ████ = >80% utilized, ░░░░ = <80% utilized
```

## Risk: Overallocation

🟡 **Dev 3 (Frontend)**: 98% utilization
- Risk: Burnout, no buffer for urgent issues
- Mitigation: Move 8 hours to Dev 4 next week

🟢 **All others**: Within healthy range (85-95%)
```

## Related Skills

- [product-owner](../product-owner/skill.md) - Product backlog and user story management
- [backend-developer](../backend-developer/skill.md) - Rails development implementation
- [frontend-developer](../frontend-developer/skill.md) - UI/UX implementation
- [devops-engineer](../devops-engineer/skill.md) - Deployment and infrastructure
- [qa-tester](../qa-tester/skill.md) - Quality assurance and testing
- [technical-architect](../technical-architect/skill.md) - Technical decisions and architecture

## Best Practices

### Project Planning
1. **Start with Why**: Clear business case and objectives
2. **SMART Goals**: Specific, Measurable, Achievable, Relevant, Time-bound
3. **Bottom-Up Estimating**: Involve team in task breakdown
4. **Buffer Time**: Add 15-20% contingency for unknowns
5. **Dependencies First**: Identify and manage critical path

### Risk Management
1. **Proactive Identification**: Weekly risk review
2. **Risk Register**: Centralized tracking
3. **Probability × Impact**: Prioritize high-impact risks
4. **Mitigation Plans**: Don't just identify, plan actions
5. **Escalation Path**: Know when to escalate

### Communication
1. **Stakeholder Analysis**: Tailor communication to audience
2. **Consistent Cadence**: Regular, predictable updates
3. **Traffic Lights**: Visual status (🟢🟡🔴) for quick scanning
4. **Action-Oriented**: Always include next steps
5. **Two-Way**: Encourage feedback and questions

### Team Management
1. **Sustainable Pace**: No consistent overtime
2. **Work-Life Balance**: Respect boundaries
3. **Transparent**: Share information openly
4. **Empowerment**: Let team make technical decisions
5. **Recognition**: Celebrate wins, big and small

### Change Control
1. **Formal Process**: All changes documented
2. **Impact Analysis**: Scope, schedule, budget impact
3. **Approval Required**: Stakeholder sign-off
4. **Communication**: Notify all affected parties
5. **Lessons Learned**: Review changes in retrospectives

### Quality Management
1. **Definition of Done**: Clear, agreed-upon criteria
2. **Automated Testing**: Regression prevention
3. **Code Reviews**: Mandatory, constructive
4. **Continuous Integration**: Catch issues early
5. **Technical Debt**: Track and pay down regularly

## Common Commands

```bash
# Project setup
mkdir -p project-docs/{charter,plans,reports,risks}

# Generate status report
bin/rails runner '
  puts "=== Weekly Status Report ==="
  puts "Bookings this week: #{Booking.where("created_at >= ?", 1.week.ago).count}"
  puts "Revenue this week: #{Booking.where("created_at >= ?", 1.week.ago).sum(:total_price_cents) / 100.0}"
  puts "Active customers: #{Client.where(active: true).count}"
'

# Team velocity tracking
bin/rails runner '
  # Last 3 sprints velocity
  sprints = [
    { number: 14, committed: 28, completed: 28 },
    { number: 15, committed: 32, completed: 32 },
    { number: 16, committed: 30, completed: 30 }
  ]

  avg_velocity = sprints.sum { |s| s[:completed] } / sprints.count.to_f
  puts "Average velocity: #{avg_velocity.round(1)} points"

  completion_rate = (sprints.sum { |s| s[:completed] } / sprints.sum { |s| s[:committed] }.to_f * 100).round(1)
  puts "Completion rate: #{completion_rate}%"
'

# Risk tracking
bin/rails runner '
  risks = [
    { id: "R1", description: "Pricing complexity", impact: "High", probability: "Medium" },
    { id: "R2", description: "Resource availability", impact: "Medium", probability: "High" }
  ]

  puts "=== Active Risks ==="
  risks.each do |r|
    puts "#{r[:id]}: #{r[:description]} (#{r[:impact]}/#{r[:probability]})"
  end
'

# Budget tracking
bin/rails runner '
  budget = {
    planned: 120_000,
    spent: 72_000,
    forecast: 118_500
  }

  percent_spent = (budget[:spent] / budget[:planned].to_f * 100).round(1)
  variance = budget[:planned] - budget[:forecast]

  puts "Budget: $#{budget[:spent].to_s.reverse.gsub(/(\d{3})(?=\d)/, "\\1,").reverse}/$#{budget[:planned].to_s.reverse.gsub(/(\d{3})(?=\d)/, "\\1,").reverse} (#{percent_spent}%)"
  puts "Variance: $#{variance} #{variance > 0 ? "under" : "over"} budget"
'
```

## Key Metrics to Track

### Schedule Metrics
- **Planned vs. Actual Completion**: On-time delivery rate
- **Burndown**: Sprint progress tracking
- **Velocity**: Story points completed per sprint
- **Cycle Time**: Time from start to done

### Budget Metrics
- **Burn Rate**: Monthly spending rate
- **Earned Value (EV)**: Value of work completed
- **Cost Variance (CV)**: Budget vs. actual
- **Cost Performance Index (CPI)**: EV / Actual Cost

### Quality Metrics
- **Defect Rate**: Bugs per sprint
- **Test Coverage**: Percentage of code tested
- **Technical Debt**: Unresolved issues
- **Code Review Turnaround**: Time to review PRs

### Team Metrics
- **Team Satisfaction**: Survey scores
- **Utilization Rate**: Capacity vs. allocation
- **Overtime Hours**: Sustainability indicator
- **Turnover Rate**: Team stability

### Stakeholder Metrics
- **Customer Satisfaction (CSAT)**: Feature acceptance
- **Net Promoter Score (NPS)**: Customer advocacy
- **Stakeholder Engagement**: Meeting attendance, feedback
- **Change Request Rate**: Scope stability
