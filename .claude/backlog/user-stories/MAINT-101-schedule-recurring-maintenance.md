# User Story: Schedule Recurring Maintenance Tasks

**Story ID**: MAINT-101
**Epic**: [MAINT - Preventive Maintenance](../epics/MAINT-preventive-maintenance.md)
**Status**: Ready
**Priority**: CRITICAL (P0)
**Points**: 13
**Sprint**: Sprint 17
**Assigned To**: backend-developer

---

## Story

**As a** Fleet Manager
**I want to** schedule recurring maintenance tasks for equipment
**So that** I can prevent equipment failures and extend asset lifespan

---

## Acceptance Criteria

- [ ] **Given** I have a product in my inventory
      **When** I create a maintenance schedule
      **Then** I can set frequency (hours-based, days-based, or usage-based)

- [ ] **Given** I have created a maintenance schedule
      **When** I specify the interval (e.g., every 100 hours or every 30 days)
      **Then** The system calculates the next due date automatically

- [ ] **Given** A maintenance task is due
      **When** The scheduled date arrives
      **Then** The system marks it as "due" and sends notification

- [ ] **Given** I have equipment with multiple maintenance schedules
      **When** I view the equipment details
      **Then** I can see all scheduled maintenance tasks with next due dates

- [ ] **Given** A maintenance task is completed
      **When** I log the completion
      **Then** The next occurrence is automatically scheduled based on the interval

- [ ] **Given** I want to assign maintenance to a specific technician
      **When** Creating a schedule
      **Then** I can select from available technicians

---

## Technical Details

### Database Changes
```sql
CREATE TABLE maintenance_schedules (
  id BIGSERIAL PRIMARY KEY,
  product_id BIGINT NOT NULL REFERENCES products(id),
  company_id BIGINT NOT NULL REFERENCES companies(id),
  assigned_to_id BIGINT REFERENCES users(id),

  name VARCHAR(255) NOT NULL,
  description TEXT,

  -- Frequency configuration
  frequency VARCHAR(50) NOT NULL CHECK (frequency IN ('hours_based', 'days_based', 'usage_based')),
  interval_value INTEGER NOT NULL,
  interval_unit VARCHAR(50) NOT NULL, -- 'hours', 'days', 'rentals'

  -- Scheduling
  last_completed_at TIMESTAMP,
  next_due_date TIMESTAMP,

  -- Status
  status VARCHAR(50) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'overdue')),
  enabled BOOLEAN DEFAULT TRUE,

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_maintenance_schedules_product ON maintenance_schedules(product_id);
CREATE INDEX idx_maintenance_schedules_next_due ON maintenance_schedules(next_due_date) WHERE enabled = TRUE;
CREATE INDEX idx_maintenance_schedules_company ON maintenance_schedules(company_id);
```

### API Endpoints
- `POST /api/v1/maintenance_schedules` - Create maintenance schedule
- `GET /api/v1/maintenance_schedules` - List all schedules (with filtering)
- `GET /api/v1/maintenance_schedules/:id` - Get schedule details
- `PATCH /api/v1/maintenance_schedules/:id` - Update schedule
- `DELETE /api/v1/maintenance_schedules/:id` - Delete schedule
- `GET /api/v1/products/:id/maintenance_schedules` - Get schedules for product
- `GET /api/v1/maintenance_schedules/due` - Get upcoming/overdue schedules

### Models
```ruby
class MaintenanceSchedule < ApplicationRecord
  belongs_to :product
  belongs_to :company
  belongs_to :assigned_to, class_name: 'User', optional: true
  has_many :maintenance_logs

  enum frequency: { hours_based: 'hours_based', days_based: 'days_based', usage_based: 'usage_based' }
  enum status: { scheduled: 'scheduled', in_progress: 'in_progress', completed: 'completed', overdue: 'overdue' }

  validates :name, :frequency, :interval_value, :interval_unit, presence: true
  validates :interval_value, numericality: { greater_than: 0 }

  scope :enabled, -> { where(enabled: true) }
  scope :due_soon, -> { where('next_due_date <= ?', 7.days.from_now) }
  scope :overdue, -> { where('next_due_date < ?', Time.current).where.not(status: 'completed') }

  # Calculate next due date based on last completion
  def calculate_next_due_date
    return unless last_completed_at

    case frequency
    when 'hours_based'
      last_completed_at + interval_value.hours
    when 'days_based'
      last_completed_at + interval_value.days
    when 'usage_based'
      # Calculate based on estimated usage pattern
      calculate_usage_based_due_date
    end
  end

  def mark_overdue!
    update(status: :overdue) if next_due_date < Time.current
  end

  private

  def calculate_usage_based_due_date
    # For usage-based (e.g., every 50 rentals), estimate based on avg rental frequency
    avg_rentals_per_day = product.bookings.count / product.created_at.to_date.to_s(:number_of_days_old)
    days_until_due = interval_value / avg_rentals_per_day
    last_completed_at + days_until_due.days
  end
end
```

### Services
```ruby
class MaintenanceScheduleService
  def create_schedule(product:, params:)
    schedule = product.maintenance_schedules.build(params)
    schedule.next_due_date = calculate_initial_due_date(schedule)
    schedule.save!
    schedule
  end

  def complete_maintenance(schedule, completed_by:, notes: nil)
    ActiveRecord::Base.transaction do
      # Log the completion
      log = schedule.maintenance_logs.create!(
        performed_by: completed_by,
        completed_at: Time.current,
        notes: notes
      )

      # Update schedule
      schedule.update!(
        last_completed_at: Time.current,
        next_due_date: schedule.calculate_next_due_date,
        status: :scheduled
      )

      # Remove availability block if exists
      remove_availability_block(schedule)

      log
    end
  end

  private

  def calculate_initial_due_date(schedule)
    case schedule.frequency
    when 'hours_based'
      schedule.interval_value.hours.from_now
    when 'days_based'
      schedule.interval_value.days.from_now
    when 'usage_based'
      # Estimate based on typical usage
      30.days.from_now
    end
  end

  def remove_availability_block(schedule)
    AvailabilityBlock.where(
      blockable: schedule,
      blockable_type: 'MaintenanceSchedule'
    ).destroy_all
  end
end
```

---

## Tasks

### Backend Tasks
- [ ] **TASK-001**: Create migration for maintenance_schedules table (2h) - `backend-developer`
- [ ] **TASK-002**: Create MaintenanceSchedule model with validations (3h) - `backend-developer`
- [ ] **TASK-003**: Create MaintenanceScheduleService (4h) - `backend-developer`
- [ ] **TASK-004**: Create API controller and routes (3h) - `backend-developer`
- [ ] **TASK-005**: Implement next_due_date calculation logic (3h) - `backend-developer`
- [ ] **TASK-006**: Write model unit tests (2h) - `backend-developer`
- [ ] **TASK-007**: Write API integration tests (2h) - `backend-developer`

### Testing Tasks
- [ ] **TASK-101**: Write RSpec model tests (2h) - `qa-tester`
- [ ] **TASK-102**: Write API request specs (2h) - `qa-tester`
- [ ] **TASK-103**: Manual QA testing (different frequencies) (2h) - `qa-tester`

### DevOps Tasks
- [ ] **TASK-201**: Review and run database migration (30min) - `devops-engineer`

**Total Estimated Time**: 25.5 hours (~13 story points)

---

## Dependencies

- **Depends on**: Product model (exists)
- **Blocks**: MAINT-103 (notifications require schedules)
- **Related to**: MAINT-104 (availability blocking), MAINT-105 (maintenance history)

---

## Definition of Done

- [ ] All acceptance criteria met
- [ ] Code complete and peer reviewed
- [ ] Unit tests passing (>90% coverage)
- [ ] Integration tests passing
- [ ] API documentation updated
- [ ] Manual QA testing complete
- [ ] Can create time-based and usage-based schedules
- [ ] Next due date calculates correctly
- [ ] Works with 100+ maintenance schedules
- [ ] Performance acceptable (<200ms for API calls)

---

## Notes

### Business Rules
- Hours-based: Used for equipment with hour meters (excavators, generators)
- Days-based: Used for calendar-based maintenance (monthly inspections)
- Usage-based: Based on number of rentals (every 50 rentals, inspect brakes)

### Edge Cases to Handle
- What if equipment has never been rented? (use estimated pattern)
- What if last_completed_at is null? (calculate from creation date)
- What if technician is deleted? (assigned_to becomes null, still valid)
- Overlapping maintenance schedules (both allowed, separate tasks)

### Future Enhancements (Phase 2)
- Maintenance task checklists (sub-tasks)
- Automatic parts ordering when maintenance due
- Integration with calendar systems
- Mobile app for technicians

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| 2026-02-28 | Product Owner | Story created |

---

## Status History

| Date | Status | Notes |
|------|--------|-------|
| 2026-02-28 | Ready | Prioritized for Sprint 17 |
