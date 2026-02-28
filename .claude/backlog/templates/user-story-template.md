# User Story: [Story Title]

**Story ID**: [EPIC-ID]-[NUMBER] (e.g., RB-101)
**Epic**: [Link to epic file]
**Status**: Backlog
**Priority**: Medium
**Points**: [Story Points]
**Sprint**: [Sprint Number or "Backlog"]
**Assigned To**: [Skill Name] (e.g., backend-developer)

---

## Story

**As a** [user role]
**I want to** [action/feature]
**So that** [business value/benefit]

---

## Acceptance Criteria

- [ ] **Given** [context/precondition]
      **When** [action]
      **Then** [expected result]

- [ ] **Given** [context/precondition]
      **When** [action]
      **Then** [expected result]

- [ ] **Given** [context/precondition]
      **When** [action]
      **Then** [expected result]

---

## Technical Details

### Database Changes
```sql
-- Migrations needed
-- e.g., CREATE TABLE recurring_bookings...
```

### API Endpoints
- `POST /api/v1/[resource]` - [Description]
- `GET /api/v1/[resource]/:id` - [Description]
- `PATCH /api/v1/[resource]/:id` - [Description]
- `DELETE /api/v1/[resource]/:id` - [Description]

### Models
- `[ModelName]` - [Description of model and key methods]

### Services
- `[ServiceName]` - [Description of service logic]

---

## Tasks

### Backend Tasks
- [ ] **TASK-001**: Create migration for [table] (2h) - `backend-developer`
- [ ] **TASK-002**: Create [ModelName] model with validations (3h) - `backend-developer`
- [ ] **TASK-003**: Create [ServiceName] service (4h) - `backend-developer`
- [ ] **TASK-004**: Create API endpoints (3h) - `backend-developer`
- [ ] **TASK-005**: Write unit tests (2h) - `backend-developer`
- [ ] **TASK-006**: Write integration tests (2h) - `backend-developer`

### Testing Tasks
- [ ] **TASK-101**: Write RSpec tests (2h) - `qa-tester`
- [ ] **TASK-102**: Write API contract tests (1h) - `api-tester`
- [ ] **TASK-103**: Manual QA testing (1h) - `qa-tester`

### DevOps Tasks
- [ ] **TASK-201**: Update Docker configuration (1h) - `devops-engineer`
- [ ] **TASK-202**: Deploy to staging (30min) - `devops-engineer`

**Total Estimated Time**: [X hours]

---

## Dependencies

- Depends on: [Story IDs that must be completed first]
- Blocks: [Story IDs that are waiting for this]
- Related to: [Related story IDs]

---

## Definition of Done

- [ ] All acceptance criteria met
- [ ] Code complete and peer reviewed
- [ ] Unit tests passing (>90% coverage)
- [ ] Integration tests passing
- [ ] API documentation updated
- [ ] Manual QA testing complete
- [ ] Deployed to staging
- [ ] Product Owner acceptance
- [ ] No critical bugs
- [ ] Performance acceptable (<500ms)

---

## Notes

[Any additional context, design decisions, or discussion points]

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| 2026-02-28 | Product Owner | Story created |
|  |  |  |

---

## Status History

| Date | Status | Notes |
|------|--------|-------|
| 2026-02-28 | Backlog | Initial creation |
|  |  |  |
