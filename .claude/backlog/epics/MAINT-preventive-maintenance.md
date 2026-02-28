# Epic: Preventive Maintenance Scheduling

**Epic ID**: MAINT
**Status**: Backlog
**Priority**: CRITICAL
**Business Value**: HIGH
**Target Release**: Phase 1 - Q2 2026

---

## Overview

Enable rental companies to schedule, track, and manage preventive maintenance for their rental inventory. This prevents equipment failures, extends asset lifespan, and ensures safety compliance.

## Business Problem

Rental companies lose significant revenue when equipment fails during rentals due to lack of preventive maintenance. Manual tracking of maintenance schedules is error-prone and often results in:
- Unexpected equipment failures costing $500-2000 per incident
- Safety liability issues
- Reduced equipment lifespan (30-40% decrease)
- Poor customer experience leading to churn

## Success Metrics

- **Primary**: 80% reduction in equipment failures during rentals
- **Secondary**:
  - 25% increase in equipment lifespan
  - 90% compliance with scheduled maintenance
  - 50% reduction in emergency repairs
  - <5 min average time to schedule maintenance

## User Personas

1. **Fleet Manager** - Oversees all equipment maintenance schedules
2. **Maintenance Technician** - Performs the actual maintenance work
3. **Operations Manager** - Needs visibility into equipment availability
4. **Inventory Manager** - Tracks equipment condition and retirement decisions

---

## User Stories

### Must Have (P0)
- [ ] MAINT-101: Schedule recurring maintenance tasks (13 pts)
- [ ] MAINT-102: Preventive maintenance calendar (8 pts)
- [ ] MAINT-103: Maintenance due notifications (5 pts)
- [ ] MAINT-104: Block equipment from booking when maintenance due (8 pts)
- [ ] MAINT-105: Track maintenance history per equipment (5 pts)

### Should Have (P1)
- [ ] MAINT-106: Maintenance checklist templates (5 pts)
- [ ] MAINT-107: Maintenance cost tracking (3 pts)
- [ ] MAINT-108: Vendor management for third-party maintenance (5 pts)
- [ ] MAINT-109: Equipment condition scoring (3 pts)

### Nice to Have (P2)
- [ ] MAINT-110: Predictive maintenance alerts (ML-based) (13 pts)
- [ ] MAINT-111: Mobile app for technicians (21 pts)
- [ ] MAINT-112: Parts inventory integration (8 pts)

**Total Story Points**: 97 pts (Must Have: 39 pts)

---

## Technical Architecture

### New Models
```ruby
class MaintenanceSchedule < ApplicationRecord
  belongs_to :product
  belongs_to :assigned_to, class_name: 'User', optional: true

  enum frequency: [:hours_based, :days_based, :usage_based]
  enum status: [:scheduled, :in_progress, :completed, :overdue]

  validates :interval_value, presence: true
  validates :interval_unit, presence: true
end

class MaintenanceLog < ApplicationRecord
  belongs_to :product
  belongs_to :maintenance_schedule, optional: true
  belongs_to :performed_by, class_name: 'User'

  validates :completed_at, presence: true
end

class MaintenanceTask < ApplicationRecord
  belongs_to :maintenance_schedule

  validates :description, presence: true
end
```

### New Tables
- `maintenance_schedules` - Recurring maintenance definitions
- `maintenance_logs` - Historical record of performed maintenance
- `maintenance_tasks` - Checklist items for each maintenance type
- `equipment_availability_blocks` - Track when equipment unavailable for maintenance

### API Endpoints
- `POST /api/v1/maintenance_schedules` - Create schedule
- `GET /api/v1/maintenance_schedules` - List all schedules
- `PATCH /api/v1/maintenance_schedules/:id` - Update schedule
- `GET /api/v1/maintenance_schedules/due` - Get upcoming/overdue maintenance
- `POST /api/v1/maintenance_logs` - Log completed maintenance
- `GET /api/v1/products/:id/maintenance_history` - Equipment history

### Background Jobs
- `MaintenanceDueCheckerJob` - Runs daily to check for due maintenance
- `MaintenanceNotificationJob` - Sends alerts to technicians
- `AvailabilityBlockerJob` - Blocks equipment from bookings

---

## Dependencies

### Blocking
- None - can start immediately

### Integration Points
- Product model (existing) - Links to equipment
- Calendar system (EPIC: CAL) - Visual maintenance calendar
- Notification system (EPIC: EMAIL) - Send maintenance alerts
- Parts inventory (EPIC: PARTS) - Track parts used in maintenance

---

## Risks & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Complex scheduling logic | Medium | High | Start with simple time-based, add usage-based later |
| Equipment availability conflicts | High | Medium | Build robust blocking mechanism first |
| Data migration for existing equipment | Low | Medium | Provide bulk import tool |
| User adoption (new workflow) | Medium | High | Create training materials, phased rollout |

---

## Out of Scope

- Automated parts ordering (Phase 2)
- IoT sensor integration for predictive maintenance (Phase 3)
- Third-party service provider marketplace (Phase 3)
- Warranty tracking (different epic)

---

## Estimation

**Total Effort**: 15-20 days
- Backend: 10 days
- Frontend: 6 days
- Testing: 4 days
- DevOps: 1 day

**Team Capacity**: 2 developers + 1 QA
**Target Completion**: End of Sprint 18

---

## Success Criteria

- [ ] Can schedule daily, weekly, monthly, and usage-based maintenance
- [ ] Equipment automatically blocked from booking when maintenance due
- [ ] Technicians receive notifications 3 days before maintenance due
- [ ] Complete maintenance history visible per equipment
- [ ] Mobile-responsive interface for technicians
- [ ] 95% test coverage
- [ ] <500ms API response times
- [ ] Successfully tested with 1000+ maintenance schedules

---

## Related Epics

- **ROUTE**: Route optimization for maintenance technicians
- **MOBILE**: Mobile app for field technicians
- **PARTS**: Parts inventory integration
- **CAL**: Calendar integration for scheduling

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| 2026-02-28 | Product Owner | Epic created |
