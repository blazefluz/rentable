# Quick Start Guide for Development Skills

**For**: backend-developer, frontend-developer, qa-tester, devops-engineer
**Last Updated**: February 28, 2026

---

## Your Sprint 17 Work (Starts March 3, 2026)

### Backend Developer - You Have 18 Points

**Primary Story**: MAINT-101 - Schedule Recurring Maintenance (13 pts)
```bash
# Read your story
cat .claude/backlog/user-stories/MAINT-101-schedule-recurring-maintenance.md

# Your tasks:
1. Create maintenance_schedules table migration
2. Create MaintenanceSchedule model with validations
3. Implement frequency calculation logic
4. Create MaintenanceScheduleService
5. Build API endpoints (CRUD)
6. Write model and integration tests
```

**Secondary Story**: MAINT-103 - Maintenance Notifications (5 pts)
```bash
# Your tasks:
1. Create MaintenanceDueCheckerJob
2. Create MaintenanceNotificationJob
3. Email notification template
4. Schedule job to run daily
```

---

### Frontend Developer - You Have 14 Points

**Primary Story**: MAINT-102 - Maintenance Calendar View (8 pts)
```bash
# Your tasks:
1. Create maintenance calendar component
2. Display upcoming/overdue maintenance
3. Color-code by status
4. Add filters
5. Drill-down to details
```

**Supporting Tasks**:
- MAINT-104 UI portions (3 pts)
- MAINT-105 History display (3 pts)

---

### QA Tester - You Have 10 Points

**Your Testing Focus**:
```bash
# Test each story:
1. MAINT-101: Test all frequency types (hours, days, usage)
2. MAINT-102: Visual regression testing
3. MAINT-103: Test notification delivery
4. MAINT-104: Test availability blocking edge cases
5. Integration testing across all stories
```

**Test Coverage Target**: >90%

---

### DevOps Engineer - You Have 4 Points

**Your Tasks**:
```bash
1. Review and run database migrations (1 pt)
2. Set up background job monitoring (2 pts)
3. Performance test availability checks (1 pt)
```

---

## Where to Find Information

### Daily Work
```bash
# What am I working on this sprint?
cat .claude/backlog/sprints/sprint-17-preventive-maintenance.md

# Detailed user story
cat .claude/backlog/user-stories/MAINT-101-schedule-recurring-maintenance.md

# Epic context (big picture)
cat .claude/backlog/epics/MAINT-preventive-maintenance.md
```

### Planning Ahead
```bash
# What's in Sprint 18?
cat .claude/backlog/sprints/sprint-18-financial-reporting.md

# What's in Sprint 19?
cat .claude/backlog/sprints/sprint-19-calendar-email-automation.md

# Full roadmap
cat .claude/backlog/PRODUCT_ROADMAP.md
```

---

## Sprint 17 Daily Goals

### Week 1: March 3-7

**Monday (Day 1)**
- All: Sprint planning meeting
- Backend: Start MAINT-101 database/models
- Frontend: Set up calendar component

**Tuesday (Day 2)**
- Backend: MAINT-101 models complete
- Frontend: Calendar rendering

**Wednesday (Day 3)**
- Backend: MAINT-101 API endpoints
- Frontend: Calendar UI polish

**Thursday (Day 4)**
- Backend: Start MAINT-103 (notifications)
- Frontend: Complete MAINT-102
- QA: Start testing MAINT-101

**Friday (Day 5)**
- Backend: Complete MAINT-101 ✓
- Frontend: Complete MAINT-102 ✓
- QA: Test MAINT-102

---

### Week 2: March 10-14

**Monday (Day 6)**
- Backend: Complete MAINT-103 ✓
- Backend: Start MAINT-104
- Frontend: Start MAINT-105

**Tuesday (Day 7)**
- Backend: MAINT-104 backend complete
- Frontend: Continue MAINT-105

**Wednesday (Day 8)**
- Backend: MAINT-104 frontend integration
- Frontend: Complete MAINT-105 ✓
- QA: Test MAINT-103, MAINT-104

**Thursday (Day 9)**
- All: Integration testing
- All: Bug fixes
- QA: Final testing pass

**Friday (Day 10)**
- All: Sprint demo prep
- All: Retrospective
- All: Sprint 18 planning

---

## Definition of Done Checklist

Before marking a story complete, verify:

- [ ] All acceptance criteria met
- [ ] Code reviewed and merged to main branch
- [ ] Unit tests written (>90% coverage)
- [ ] Integration tests passing
- [ ] API documentation updated (if applicable)
- [ ] Manual QA testing complete
- [ ] No critical or high-priority bugs
- [ ] Deployed to staging environment

---

## Common Commands

### Backend Developer
```bash
# Generate migration
rails generate migration CreateMaintenanceSchedules

# Run migrations
rails db:migrate

# Run tests
bundle exec rspec spec/models/maintenance_schedule_spec.rb
bundle exec rspec spec/requests/api/v1/maintenance_schedules_spec.rb

# Start server
rails server
```

### Frontend Developer
```bash
# Run dev server
npm run dev

# Run tests
npm test

# Build for production
npm run build
```

### Run All Tests
```bash
# Backend tests
bundle exec rspec

# Frontend tests
npm test

# System tests
bundle exec rspec spec/system/
```

---

## Who to Ask for Help

### Technical Questions
- **Rails/Backend**: Backend Developer Lead
- **React/Frontend**: Frontend Developer Lead
- **Testing**: QA Lead
- **DevOps/Infra**: DevOps Engineer

### Product Questions
- **Requirements**: Product Owner (Victor)
- **Priorities**: Product Owner
- **Customer Needs**: Product Owner

### Blocked?
1. Try to unblock yourself (docs, Stack Overflow)
2. Ask team member
3. Escalate to Product Owner if impacts sprint goal

---

## Sprint Ceremonies

### Daily Standup (15 min, 9:30 AM)
- What did I do yesterday?
- What will I do today?
- Any blockers?

### Sprint Review (Friday, Week 2, 3:00 PM)
- Demo completed work
- Stakeholder feedback
- Update roadmap

### Sprint Retrospective (Friday, Week 2, 4:00 PM)
- What went well?
- What didn't go well?
- Action items for next sprint

### Sprint Planning (Monday, Week 1, 10:00 AM)
- Review sprint goal
- Commit to stories
- Break down tasks

---

## Emergency Contacts

**Critical Bug in Production**:
1. Notify DevOps Engineer immediately
2. Create hotfix branch
3. Deploy fix ASAP
4. Post-mortem document

**Sprint at Risk**:
1. Notify Product Owner
2. Propose scope reduction
3. Adjust sprint plan

---

## Tips for Success

### Backend Developer
- Read the full user story before coding
- Start with tests (TDD)
- Keep services focused (Single Responsibility)
- Comment complex logic
- Use descriptive variable names

### Frontend Developer
- Follow existing component patterns
- Mobile-first responsive design
- Accessibility (a11y) matters
- Performance: lazy load, code split
- Test edge cases (empty states, errors)

### QA Tester
- Test happy path AND edge cases
- Document reproduction steps for bugs
- Performance testing matters
- Cross-browser testing
- Mobile responsive testing

### DevOps Engineer
- Zero-downtime deployments
- Monitor after each deploy
- Database migrations: reversible
- Secrets never in code
- Infrastructure as Code

---

## Resources

### Documentation
- Rails Guides: https://guides.rubyonrails.org/
- React Docs: https://react.dev/
- RSpec Docs: https://rspec.info/
- Stripe API: https://stripe.com/docs/api

### Internal Docs
- API Documentation: `/docs/api`
- Architecture Decisions: `.claude/architecture/`
- Coding Standards: `.claude/CODING_STANDARDS.md`

---

## Measuring Your Progress

### Velocity Tracking
- Your committed points: [see sprint plan]
- Your completed points: [update daily]
- Your burndown: On track? Ahead? Behind?

### Quality Metrics
- Test coverage: >90% target
- Bug count: <5 per story
- Code review feedback: Positive?
- Performance: <500ms API responses

---

## Have Questions?

**Read First**:
1. This guide
2. The sprint plan
3. The user story
4. The epic

**Still Stuck?**:
Ask in team chat or daily standup!

---

**Good luck with Sprint 17! Let's build something great! 🚀**
