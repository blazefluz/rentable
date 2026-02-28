# Product Roadmap - Rentable Platform

**Last Updated**: February 28, 2026
**Product Owner**: Victor
**Status**: Active Development

---

## Executive Summary

This roadmap outlines the strategic development plan for Rentable, a comprehensive rental management platform. The roadmap is organized into 4 phases over 12-18 months, prioritizing features that deliver immediate business value while building toward a complete enterprise solution.

### Current State (as of Feb 2026)
- Phase 0 (Foundation) **COMPLETE**: Core booking system, multi-tenancy, Stripe payments
- Sprint 16 **IN PROGRESS**: Smart pricing and automation

### Strategic Goals
1. **Phase 1 (Q2 2026)**: Fill critical gaps - maintenance, financials, communications
2. **Phase 2 (Q3 2026)**: Operational efficiency - mobile apps, logistics, proof of delivery
3. **Phase 3 (Q4 2026)**: Advanced features - forecasting, search, analytics
4. **Phase 4 (Q1 2027)**: Enterprise scale - integrations, marketplace, API platform

---

## Phase 1: Critical Business Features (Q2 2026)
**Timeline**: March - June 2026 (Sprints 17-22)
**Goal**: Address critical operational gaps blocking customer adoption

### Epics

#### 1. MAINT - Preventive Maintenance Scheduling
- **Business Value**: Reduce equipment failures by 80%, extend asset life by 25%
- **Story Points**: 39 (must-have)
- **Timeline**: Sprints 17-18 (6 weeks)
- **Dependencies**: None
- **Success Metric**: 90% compliance with maintenance schedules

**User Stories**:
- MAINT-101: Schedule recurring maintenance (13 pts) - Sprint 17
- MAINT-102: Maintenance calendar (8 pts) - Sprint 17
- MAINT-103: Maintenance due notifications (5 pts) - Sprint 17
- MAINT-104: Block equipment when maintenance due (8 pts) - Sprint 18
- MAINT-105: Maintenance history tracking (5 pts) - Sprint 18

---

#### 2. FIN - Financial Reporting & Analytics
- **Business Value**: Complete visibility into P&L, $50K+ annual savings in accounting time
- **Story Points**: 42 (must-have)
- **Timeline**: Sprints 18-19 (6 weeks)
- **Dependencies**: Existing booking/payment data
- **Success Metric**: Generate P&L in <3 seconds, 100% accuracy

**User Stories**:
- FIN-101: Profit & Loss statement (13 pts) - Sprint 18
- FIN-102: Revenue breakdown by category (8 pts) - Sprint 18
- FIN-103: Expense tracking (8 pts) - Sprint 19
- FIN-104: Equipment ROI calculation (5 pts) - Sprint 19
- FIN-105: Financial reports (monthly/quarterly/annual) (8 pts) - Sprint 19

---

#### 3. CAL - Calendar Integrations
- **Business Value**: 50% reduction in missed deliveries, 80% staff calendar adoption
- **Story Points**: 36 (must-have)
- **Timeline**: Sprints 19-20 (5 weeks)
- **Dependencies**: OAuth setup (Google, Microsoft)
- **Success Metric**: 80% of bookings synced to calendars

**User Stories**:
- CAL-101: Google Calendar two-way sync (13 pts) - Sprint 19
- CAL-102: Customer calendar invites (5 pts) - Sprint 20
- CAL-103: Availability calendar display (8 pts) - Sprint 20
- CAL-104: Maintenance schedule sync (5 pts) - Sprint 20
- CAL-105: Block unavailable dates (5 pts) - Sprint 20

---

#### 4. EMAIL - Email Marketing Automation
- **Business Value**: 20% increase in quote conversion, 30% repeat booking rate
- **Story Points**: 31 (must-have)
- **Timeline**: Sprints 20-21 (5 weeks)
- **Dependencies**: SendGrid account
- **Success Metric**: 40% email open rate, 25% revenue from automated campaigns

**User Stories**:
- EMAIL-101: Quote follow-up automation (8 pts) - Sprint 20
- EMAIL-102: Past customer re-engagement (5 pts) - Sprint 21
- EMAIL-103: Email template builder (8 pts) - Sprint 21
- EMAIL-104: Customer segmentation (5 pts) - Sprint 21
- EMAIL-105: Email analytics dashboard (5 pts) - Sprint 21

---

#### 5. ROUTE - Route Optimization (Starts in Q2, completes in Q3)
- **Business Value**: 25% reduction in delivery costs, 30% more deliveries/day
- **Story Points**: 44 (must-have)
- **Timeline**: Sprints 21-23 (8 weeks)
- **Dependencies**: Google Maps API
- **Success Metric**: 25% shorter routes, 95% on-time delivery

**User Stories**:
- ROUTE-101: Route optimization engine (13 pts) - Sprint 21
- ROUTE-102: Google Maps navigation (8 pts) - Sprint 22
- ROUTE-103: Delivery time windows (5 pts) - Sprint 22
- ROUTE-104: Mobile app for drivers (13 pts) - Sprint 23 (Phase 2)
- ROUTE-105: Mark deliveries complete (5 pts) - Sprint 23 (Phase 2)

---

### Phase 1 Milestones

| Milestone | Target Date | Success Criteria |
|-----------|------------|------------------|
| Maintenance System Live | April 15, 2026 | 10+ companies using preventive maintenance |
| Financial Reporting Live | May 1, 2026 | CFOs can generate P&L statements |
| Calendar Integration Live | May 20, 2026 | 80% calendar sync rate |
| Email Automation Live | June 5, 2026 | First automated campaigns sent |
| Phase 1 Complete | June 30, 2026 | All 5 epics deployed to production |

---

## Phase 2: Operational Efficiency (Q3 2026)
**Timeline**: July - September 2026 (Sprints 23-28)
**Goal**: Streamline field operations and improve logistics

### Epics

#### 6. MOBILE - Mobile Application
- **Story Points**: 89
- **Timeline**: Sprints 23-26 (12 weeks)
- **Platform**: React Native (iOS + Android)
- **Success Metric**: 50% of bookings via mobile, 4.5+ star rating

**Key Features**:
- Driver app for delivery management
- Customer app for bookings
- Offline mode support
- Push notifications

---

#### 7. POD - Proof of Delivery
- **Story Points**: 55
- **Timeline**: Sprints 24-25 (6 weeks)
- **Success Metric**: 90% reduction in damage disputes
- **Integration**: Works with mobile app

**Key Features**:
- Photo capture at delivery/pickup
- Digital signatures
- Equipment condition checklists
- GPS timestamp

---

#### 8. PARTS - Parts Inventory
- **Story Points**: 58
- **Timeline**: Sprints 26-27 (6 weeks)
- **Success Metric**: 50% reduction in equipment downtime

**Key Features**:
- Parts catalog and inventory
- Link parts to equipment
- Low stock alerts
- Usage tracking during maintenance

---

### Phase 2 Milestones

| Milestone | Target Date | Success Criteria |
|-----------|------------|------------------|
| Mobile App Beta | July 30, 2026 | 50 beta testers |
| Mobile App Launch | August 20, 2026 | App store approved, public release |
| POD System Live | September 5, 2026 | 100% deliveries documented |
| Parts Inventory Live | September 25, 2026 | All parts cataloged |
| Phase 2 Complete | September 30, 2026 | All mobile and logistics features live |

---

## Phase 3: Advanced Features (Q4 2026)
**Timeline**: October - December 2026 (Sprints 29-34)
**Goal**: Add intelligence and automation for competitive advantage

### Epics

#### 9. FORECAST - Demand Forecasting
- **Story Points**: 65
- **Timeline**: Sprints 29-30 (6 weeks)
- **Tech**: Machine learning with historical data
- **Success Metric**: 90% forecast accuracy

---

#### 10. SEARCH - Advanced Search
- **Story Points**: 52
- **Timeline**: Sprints 31-32 (5 weeks)
- **Tech**: Elasticsearch or Algolia
- **Success Metric**: 30% increase in search-to-booking conversion

---

#### 11. BATCH - Bulk Operations
- **Story Points**: 45
- **Timeline**: Sprint 33 (3 weeks)
- **Success Metric**: Import 500+ products in <5 minutes

---

#### 12. CLAIMS - Insurance Claims
- **Story Points**: 48
- **Timeline**: Sprint 34 (3 weeks)
- **Success Metric**: 50% faster claim resolution

---

### Phase 3 Milestones

| Milestone | Target Date | Success Criteria |
|-----------|------------|------------------|
| Forecasting Live | November 15, 2026 | Predict demand 90% accuracy |
| Search Enhancement | December 1, 2026 | <100ms search response |
| Phase 3 Complete | December 31, 2026 | All advanced features deployed |

---

## Phase 4: Enterprise Scale (Q1 2027)
**Timeline**: January - March 2027 (Sprints 35-40)
**Goal**: Platform maturity and ecosystem expansion

### Initiatives

1. **API Platform**: Public API for third-party integrations
2. **Marketplace**: Multi-vendor rental marketplace
3. **White-label**: Allow customers to rebrand platform
4. **International**: Multi-currency, multi-language
5. **Enterprise**: SSO, advanced permissions, SLA guarantees

---

## Resource Planning

### Team Composition (Current)
- 1 Backend Developer (Rails)
- 1 Frontend Developer (React)
- 1 QA Tester
- 1 DevOps Engineer
- 1 Product Owner

### Velocity
- Current Sprint Capacity: 54 points
- Average Velocity: 45-50 points/sprint (2 weeks)

### Phase 1 Capacity Analysis
- Phase 1 Total: ~180 story points
- Estimated Sprints: 4-5 sprints (8-10 weeks)
- Timeline: March - June 2026 ✓ Achievable

---

## Success Metrics by Phase

### Phase 1 KPIs
- Equipment failure reduction: 80%
- P&L generation time: <3 seconds
- Calendar sync adoption: 80%
- Email campaign ROI: 25% of revenue
- Customer satisfaction: >4.2/5

### Phase 2 KPIs
- Mobile app downloads: 1,000+
- Mobile booking rate: 50%
- Delivery documentation: 100%
- Damage dispute reduction: 90%
- App store rating: >4.5 stars

### Phase 3 KPIs
- Forecast accuracy: 90%
- Search conversion: +30%
- Bulk import time: <5 min for 500 products
- Claim resolution time: <30 days

---

## Risk Management

### High Risks
| Risk | Impact | Mitigation | Owner |
|------|--------|------------|-------|
| Team capacity constraints | High | Hire contractors for mobile app | Product Owner |
| Third-party API dependencies (Google Maps, SendGrid) | Medium | Multi-provider fallback strategy | DevOps |
| Customer adoption resistance | Medium | Phased rollout, training materials | Product Owner |
| Technical debt accumulation | High | 20% sprint capacity for refactoring | Tech Lead |

### Medium Risks
| Risk | Impact | Mitigation | Owner |
|------|--------|------------|-------|
| Scope creep | Medium | Strict prioritization, backlog grooming | Product Owner |
| Mobile app complexity | Medium | Start with MVP, iterate | Mobile Lead |
| Data migration issues | Medium | Robust import/export tools | Backend Dev |

---

## Dependencies & Integrations

### External Services Required

**Phase 1**:
- SendGrid (Email): $15-50/month
- Google Calendar API: Free
- Microsoft Graph API: Free

**Phase 2**:
- Google Maps API: ~$300/month
- Twilio (SMS): ~$100/month
- App Store + Play Store: $100/year

**Phase 3**:
- Elasticsearch: $95/month (Elastic Cloud)
- ML Platform (AWS SageMaker): $200/month

**Total Phase 1-3 Operating Costs**: ~$1,000/month

---

## Release Strategy

### Deployment Frequency
- **Sprints 17-22**: Every 2 weeks (sprint boundary)
- **Post-MVP**: Continuous deployment with feature flags

### Rollout Approach
1. **Internal Testing**: 1 week
2. **Beta Customers**: 2-3 friendly customers, 2 weeks
3. **General Availability**: Phased rollout by company tier
4. **Monitoring**: 2-week observation period

---

## Change Management

### Communication Plan
- **Weekly**: Sprint review demos to stakeholders
- **Monthly**: Roadmap review and adjustment
- **Quarterly**: Major release announcements
- **As-needed**: Emergency hotfixes

### Documentation
- User guides for each epic
- API documentation (auto-generated)
- Video tutorials for complex features
- In-app tooltips and onboarding

---

## Open Questions & Decisions Needed

1. **Mobile App**: React Native vs. native (iOS/Android separately)?
   - **Decision**: React Native for faster development
   - **Date Needed**: Before Sprint 23

2. **Email Provider**: SendGrid vs. Postmark vs. AWS SES?
   - **Decision**: SendGrid (better deliverability, easier setup)
   - **Date Needed**: Before Sprint 20

3. **Search Engine**: Elasticsearch vs. Algolia?
   - **Decision**: TBD (Phase 3)
   - **Date Needed**: Sprint 28

---

## Backlog Prioritization Framework

### Priority Scoring
```
Score = (Business Value × 5) + (Customer Demand × 3) + (Strategic Fit × 2) - (Complexity × 1)

Business Value: 1-10 (revenue impact, cost savings)
Customer Demand: 1-10 (how many customers requesting)
Strategic Fit: 1-10 (alignment with product vision)
Complexity: 1-10 (development effort, risk)
```

### Current Top 10 Priorities
1. MAINT-101: Preventive maintenance (Score: 87)
2. FIN-101: P&L statements (Score: 85)
3. EMAIL-101: Quote follow-up (Score: 82)
4. CAL-101: Google Calendar sync (Score: 80)
5. ROUTE-101: Route optimization (Score: 78)
6. POD-101: Proof of delivery photos (Score: 75)
7. MOBILE-101: Driver mobile app (Score: 73)
8. FIN-103: Expense tracking (Score: 70)
9. MAINT-104: Block equipment for maintenance (Score: 68)
10. EMAIL-104: Customer segmentation (Score: 65)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-28 | Initial roadmap created | Product Owner |
|  |  |  |  |

---

## Next Review Date

**Scheduled**: March 31, 2026
**Participants**: Product Owner, Engineering Lead, CEO
**Agenda**: Phase 1 progress review, Phase 2 planning refinement
