# Sprint 17: Preventive Maintenance Foundation

**Sprint Goal**: Launch preventive maintenance scheduling system to prevent equipment failures

**Start Date**: March 3, 2026
**End Date**: March 16, 2026
**Sprint Duration**: 10 working days

---

## Sprint Capacity

| Team Member | Capacity (points) | Allocated | Remaining |
|-------------|-------------------|-----------|-----------|
| backend-developer | 20 | 18 | 2 |
| frontend-developer | 16 | 14 | 2 |
| qa-tester | 12 | 10 | 2 |
| devops-engineer | 10 | 4 | 6 |
| **TOTAL** | **58** | **46** | **12** |

---

## Sprint Backlog

### High Priority (Must Have)

#### MAINT-101: Schedule Recurring Maintenance Tasks (13 pts)
- **Status**: Ready
- **Assignee**: backend-developer
- **Tasks**:
  - [ ] Create maintenance_schedules table migration
  - [ ] Create MaintenanceSchedule model with validations
  - [ ] Implement frequency calculation logic (hours, days, usage-based)
  - [ ] Create MaintenanceScheduleService
  - [ ] Build API endpoints (CRUD)
  - [ ] Write model and integration tests
- **DoD**: Can create and manage recurring maintenance schedules

---

#### MAINT-102: Preventive Maintenance Calendar View (8 pts)
- **Status**: Ready
- **Assignee**: frontend-developer
- **Tasks**:
  - [ ] Create maintenance calendar component
  - [ ] Integrate with existing calendar library
  - [ ] Display upcoming and overdue maintenance
  - [ ] Color-code by status (scheduled, overdue, completed)
  - [ ] Add filters (product, technician, date range)
  - [ ] Implement drill-down to maintenance details
- **DoD**: Visual calendar showing all scheduled maintenance

---

#### MAINT-103: Maintenance Due Notifications (5 pts)
- **Status**: Ready
- **Assignee**: backend-developer
- **Tasks**:
  - [ ] Create MaintenanceDueCheckerJob (runs daily)
  - [ ] Create MaintenanceNotificationJob
  - [ ] Email notification template
  - [ ] Check for maintenance due in next 7 days
  - [ ] Send notifications to assigned technicians
  - [ ] Add notification preferences to user settings
- **DoD**: Technicians receive email 3-7 days before maintenance due

---

#### MAINT-104: Block Equipment When Maintenance Due (8 pts)
- **Status**: Ready
- **Assignee**: backend-developer
- **Tasks**:
  - [ ] Create availability blocking logic for maintenance
  - [ ] Integrate with existing booking availability checks
  - [ ] Add UI indicator when equipment blocked
  - [ ] Allow manual override (with permission)
  - [ ] Auto-remove block when maintenance completed
  - [ ] Test availability endpoint performance
- **DoD**: Equipment automatically unavailable when maintenance due

---

### Medium Priority (Should Have)

#### MAINT-105: Track Maintenance History Per Equipment (5 pts)
- **Status**: Ready
- **Assignee**: backend-developer
- **Tasks**:
  - [ ] Create maintenance_logs table
  - [ ] Create MaintenanceLog model
  - [ ] Build completion logging endpoint
  - [ ] Create maintenance history API endpoint
  - [ ] Frontend: Display maintenance history on product page
- **DoD**: Complete maintenance history visible per equipment

---

### Low Priority (Nice to Have)

#### TECH-DEBT-01: Refactor Booking Availability Logic (5 pts)
- **Status**: Backlog (if capacity allows)
- **Assignee**: backend-developer
- **Notes**: Availability logic getting complex, extract to service

---

## Sprint Commitments

**Committed**: 39 points (High Priority: MAINT-101 to MAINT-104)
**Stretch**: 5 points (MAINT-105)
**Tech Debt**: 5 points (if capacity)

---

## Task Breakdown by Role

### Backend Developer (18 pts allocated)
- MAINT-101: Schedule recurring maintenance (13 pts)
- MAINT-103: Notifications (5 pts)

### Frontend Developer (14 pts allocated)
- MAINT-102: Calendar view (8 pts)
- MAINT-104: Availability blocking UI (3 pts from 8 pts story)
- MAINT-105: History display (3 pts from 5 pts story)

### QA Tester (10 pts allocated)
- Test MAINT-101 (3 pts)
- Test MAINT-102 (2 pts)
- Test MAINT-103 (2 pts)
- Test MAINT-104 (2 pts)
- Integration testing (1 pt)

### DevOps Engineer (4 pts allocated)
- Review and run migrations (1 pt)
- Set up background job monitoring (2 pts)
- Performance testing for availability checks (1 pt)

---

## Daily Standup Plan

### Monday, March 3 (Day 1)
- Sprint planning meeting
- Environment setup
- Begin MAINT-101 backend work

### Tuesday, March 4 (Day 2)
- MAINT-101: Database and models complete
- MAINT-102: Start calendar component

### Wednesday, March 5 (Day 3)
- MAINT-101: API endpoints
- MAINT-102: Calendar rendering working

### Thursday, March 6 (Day 4)
- MAINT-101: Testing
- MAINT-103: Start notification jobs
- MAINT-102: Polish calendar UI

### Friday, March 7 (Day 5)
- MAINT-101: COMPLETE
- MAINT-102: COMPLETE
- MAINT-103: Core logic done

### Monday, March 10 (Day 6)
- MAINT-103: COMPLETE
- MAINT-104: Start availability blocking

### Tuesday, March 11 (Day 7)
- MAINT-104: Backend complete
- MAINT-105: Start history tracking

### Wednesday, March 12 (Day 8)
- MAINT-104: Frontend integration
- MAINT-105: Continue development

### Thursday, March 13 (Day 9)
- MAINT-104: COMPLETE
- MAINT-105: COMPLETE
- Integration testing begins

### Friday, March 14 (Day 10)
- Final QA testing
- Bug fixes
- Sprint demo preparation

---

## Dependencies & Blockers

### External Dependencies
- None (all internal development)

### Internal Dependencies
- Product model (exists) ✓
- User model (exists) ✓
- Background job infrastructure (exists) ✓
- Email sending (exists) ✓

### Potential Blockers
| Blocker | Mitigation | Owner |
|---------|------------|-------|
| Availability logic complexity | Pair programming session | backend-developer |
| Calendar library learning curve | Use existing FullCalendar integration | frontend-developer |
| Background job performance | Monitor and optimize if needed | devops-engineer |

---

## Definition of Done (Sprint Level)

- [ ] All committed stories (MAINT-101 to MAINT-104) completed
- [ ] All acceptance criteria met
- [ ] Code reviewed and merged to main
- [ ] Unit tests >90% coverage
- [ ] Integration tests passing
- [ ] Manual QA testing complete
- [ ] No critical or high-priority bugs
- [ ] API documentation updated
- [ ] Deployed to staging environment
- [ ] Demo prepared for sprint review

---

## Sprint Demo Agenda (March 14, 3 PM)

1. **Introduction** (5 min)
   - Sprint goal recap
   - What we committed to

2. **Demo: Schedule Maintenance** (10 min)
   - Create recurring maintenance schedule
   - Show different frequency types (hours, days, usage)
   - Assign to technician

3. **Demo: Maintenance Calendar** (10 min)
   - Visual calendar view
   - Filter by product/technician
   - Color coding by status

4. **Demo: Notifications** (5 min)
   - Show notification email
   - Demonstrate 7-day advance notice

5. **Demo: Availability Blocking** (10 min)
   - Equipment blocked when maintenance due
   - Cannot book during maintenance period
   - Manual override capability

6. **Q&A** (10 min)

---

## Retrospective Topics

### What went well?
- [To be filled during retro]

### What didn't go well?
- [To be filled during retro]

### Action items for next sprint?
- [To be filled during retro]

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Underestimated complexity of frequency calculations | Medium | Medium | Simple implementation first, iterate |
| Calendar UI performance with many events | Low | Medium | Pagination, lazy loading |
| Notification spam concerns | Medium | Low | User preferences, digest option |

---

## Sprint Metrics (To Track)

- **Velocity**: Target 39-44 points
- **Sprint Burndown**: Updated daily
- **Bugs Found**: Track count and severity
- **Code Coverage**: Maintain >90%
- **Deployment Success**: Clean staging deployment

---

## Post-Sprint Actions

- [ ] Move completed stories to Done
- [ ] Archive sprint backlog to completed/sprint-17/
- [ ] Update product roadmap progress
- [ ] Plan Sprint 18 (Financial Reporting)
- [ ] Demo to beta customers
- [ ] Collect feedback for improvements

---

## Notes

### Technical Decisions Made
- Using existing ActiveJob for background processing
- Email notifications via existing ActionMailer
- Calendar component: FullCalendar library (already in use)
- Date calculations: Use ActiveSupport helpers

### Future Enhancements (Not This Sprint)
- Mobile app for technicians
- Maintenance checklists (subtasks)
- Parts inventory integration
- Predictive maintenance (ML-based)

---

## Sprint Cheat Sheet for Skills

### Backend Developer
```bash
# Your tasks this sprint
cat .claude/backlog/sprints/sprint-17-preventive-maintenance.md | grep "backend-developer"

# Stories assigned to you
- MAINT-101 (13 pts)
- MAINT-103 (5 pts)
```

### Frontend Developer
```bash
# Your tasks this sprint
cat .claude/backlog/sprints/sprint-17-preventive-maintenance.md | grep "frontend-developer"

# Stories assigned to you
- MAINT-102 (8 pts)
- MAINT-104 UI portions (3 pts)
```

### QA Tester
```bash
# Your testing focus
- MAINT-101: Test all frequency types
- MAINT-102: Visual regression testing
- MAINT-103: Test notification delivery
- MAINT-104: Test availability blocking edge cases
```

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| 2026-02-28 | Product Owner | Sprint 17 planned |
