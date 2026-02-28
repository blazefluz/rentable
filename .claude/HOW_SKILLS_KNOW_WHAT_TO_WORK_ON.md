# How Skills Know What to Work On

This document explains the complete workflow of how skills automatically know their assignments and execute work.

## The Big Picture

```
┌─────────────────────────────────────────────────────────────┐
│                   WORK INTAKE FLOW                          │
└─────────────────────────────────────────────────────────────┘

1. STAKEHOLDER REQUEST
   │
   ├─→ "We need recurring bookings"
   │
   ↓

2. WORK INTAKE MANAGER SKILL
   │
   ├─→ Captures request
   ├─→ Creates Epic: recurring-bookings
   ├─→ Breaks into 6 User Stories
   ├─→ Generates 24 Tasks
   │
   ↓

3. PRODUCT BACKLOG (.claude/backlog/)
   │
   ├─→ epics/recurring-bookings.md
   ├─→ user-stories/RB-101.md, RB-102.md, ...
   ├─→ tasks/backend/assigned.md (12 tasks)
   ├─→ tasks/frontend/assigned.md (8 tasks)
   ├─→ tasks/testing/assigned.md (4 tasks)
   │
   ↓

4. SPRINT PLANNING
   │
   ├─→ Product Owner prioritizes
   ├─→ Team estimates story points
   ├─→ Stories added to Sprint 16
   │
   ↓

5. SKILLS READ THEIR ASSIGNMENTS
   │
   ├─→ backend-developer reads tasks/backend/assigned.md
   ├─→ frontend-developer reads tasks/frontend/assigned.md
   ├─→ qa-tester reads tasks/testing/assigned.md
   │
   ↓

6. SKILLS EXECUTE WORK
   │
   ├─→ backend-developer: Creates RecurringBooking model
   ├─→ backend-developer: Creates API endpoints
   ├─→ qa-tester: Writes tests
   │
   ↓

7. SKILLS UPDATE STATUS
   │
   ├─→ Mark tasks complete: [x]
   ├─→ Update story status: "In Review"
   ├─→ Notify next skill in chain
   │
   ↓

8. MVP RELEASE CONDUCTOR
   │
   ├─→ Reads completed stories
   ├─→ Runs automated tests
   ├─→ Deploys to production
   └─→ Generates release report
```

## File Structure Overview

```
.claude/
├── backlog/                        # Product backlog (work to do)
│   ├── README.md                   # How to use backlog
│   ├── epics/                      # Large features
│   │   ├── recurring-bookings.md
│   │   ├── smart-pricing.md
│   │   └── customer-portal.md
│   ├── user-stories/               # Individual stories
│   │   ├── RB-101-create-recurring.md
│   │   ├── RB-102-background-job.md
│   │   ├── PRICE-101-pricing-engine.md
│   │   └── ...
│   ├── sprints/                    # Sprint planning
│   │   ├── sprint-14.md
│   │   ├── sprint-15.md
│   │   ├── sprint-16.md
│   │   └── current-sprint.md       # ← Skills read this
│   ├── tasks/                      # Granular tasks
│   │   ├── backend/
│   │   │   └── assigned.md         # ← backend-developer reads this
│   │   ├── frontend/
│   │   │   └── assigned.md         # ← frontend-developer reads this
│   │   ├── testing/
│   │   │   └── assigned.md         # ← qa-tester reads this
│   │   └── devops/
│   │       └── assigned.md         # ← devops-engineer reads this
│   ├── templates/                  # Templates for new work
│   │   ├── epic-template.md
│   │   ├── user-story-template.md
│   │   ├── bug-template.md
│   │   └── task-template.md
│   └── completed/                  # Archive
│       ├── sprint-14/
│       └── sprint-15/
│
└── skills/                         # Specialist skills
    ├── work-intake-manager/        # Creates & assigns work
    ├── backend-developer/          # Reads tasks/backend/assigned.md
    ├── frontend-developer/         # Reads tasks/frontend/assigned.md
    ├── qa-tester/                  # Reads tasks/testing/assigned.md
    ├── devops-engineer/            # Reads tasks/devops/assigned.md
    ├── mvp-release-conductor/      # Orchestrates release
    ├── product-owner/              # Manages backlog
    └── project-manager/            # Tracks progress
```

## Step-by-Step Example

### Scenario: Add "Recurring Bookings" Feature

#### Step 1: Stakeholder Request

```bash
# Stakeholder (you) provides requirement
"We need customers to be able to create recurring bookings"
```

#### Step 2: Work Intake Manager Captures Request

```bash
bin/rails runner <<'RUBY'
require 'work_intake_manager'

manager = WorkIntakeManager.new

# Capture feature request
manager.intake_feature_request(
  "Customers need to create recurring bookings for weekly rentals"
)
RUBY
```

**What happens:**
```
✅ Created Epic: recurring-bookings
📝 Generated 6 User Stories:
   - RB-101: Create RecurringBooking model (5 pts)
   - RB-102: Background job for generation (8 pts)
   - RB-103: API endpoints (5 pts)
   - RB-104: Recurring booking UI (8 pts)
   - RB-105: Availability checking (8 pts)
   - RB-106: Testing (3 pts)

📊 Total: 37 story points
📅 Estimated: 2 sprints

👥 Task Assignments Created:
   - 12 tasks → .claude/backlog/tasks/backend/assigned.md
   - 8 tasks → .claude/backlog/tasks/frontend/assigned.md
   - 4 tasks → .claude/backlog/tasks/testing/assigned.md
```

#### Step 3: Files Created

**File: `.claude/backlog/epics/recurring-bookings.md`**
```markdown
# Epic: Recurring Bookings

**Epic ID**: RB
**Status**: Backlog
**Business Value**: High
**Total Points**: 37

## Description
Allow customers to create bookings that repeat on a schedule...

## User Stories
- RB-101: Create RecurringBooking model
- RB-102: Background job
- ...
```

**File: `.claude/backlog/user-stories/RB-101-create-recurring.md`**
```markdown
# User Story: Create RecurringBooking Model

**Story ID**: RB-101
**Epic**: recurring-bookings
**Status**: Backlog
**Points**: 5
**Assigned To**: backend-developer

## Story
As a rental manager
I want to store recurring booking patterns
So that the system can auto-generate bookings

## Tasks
### Backend Tasks
- [ ] TASK-001: Create migration (2h) - backend-developer
- [ ] TASK-002: Create model with validations (3h) - backend-developer
- [ ] TASK-003: Write unit tests (2h) - backend-developer
...
```

**File: `.claude/backlog/tasks/backend/assigned.md`**
```markdown
# Backend Developer - Assigned Tasks

## Current Sprint (Sprint 16)

### RB-101: Create RecurringBooking Model
- [ ] TASK-001: Create migration for recurring_bookings table (2h)
- [ ] TASK-002: Create RecurringBooking model with validations (3h)
- [ ] TASK-003: Add associations to Booking model (1h)
- [ ] TASK-004: Write unit tests for RecurringBooking (2h)

### RB-102: Background Job
- [ ] TASK-005: Create GenerateRecurringBookingsJob (4h)
- [ ] TASK-006: Add Sidekiq cron schedule (1h)
- [ ] TASK-007: Test job execution (2h)

### RB-103: API Endpoints
- [ ] TASK-008: Create RecurringBookingsController (3h)
- [ ] TASK-009: Add routes for CRUD operations (1h)
- [ ] TASK-010: Write API integration tests (2h)

...
```

#### Step 4: Sprint Planning

```bash
# Product Owner prioritizes and adds to sprint
bin/rails runner <<'RUBY'
manager = WorkIntakeManager.new

manager.plan_sprint(
  sprint_number: 16,
  stories: ['RB-101', 'RB-102', 'RB-103']  # First 3 stories
)
RUBY
```

**Result:**
```
✅ Sprint 16 planned
📊 18 points committed
📝 Updated .claude/backlog/sprints/current-sprint.md
📝 Updated task assignments
```

**File: `.claude/backlog/sprints/current-sprint.md`**
```markdown
# Current Sprint: Sprint 16

**Sprint Goal**: Implement recurring bookings backend

## Sprint Backlog

- [ ] **RB-101**: Create RecurringBooking model (5 pts) - backend-developer
- [ ] **RB-102**: Background job (8 pts) - backend-developer
- [ ] **RB-103**: API endpoints (5 pts) - backend-developer

Total: 18 points
```

#### Step 5: Backend Developer Skill Reads Assignment

```ruby
# In backend-developer skill
class BackendDeveloper
  def initialize
    # Automatically load assigned work
    @my_tasks = load_assigned_tasks
    @current_sprint = load_current_sprint
  end

  def load_assigned_tasks
    # Read the assigned tasks file
    file = '.claude/backlog/tasks/backend/assigned.md'
    tasks = File.read(file)

    # Parse uncompleted tasks
    tasks.lines.select { |line| line.start_with?('- [ ]') }
  end

  def load_current_sprint
    # Read current sprint file
    file = '.claude/backlog/sprints/current-sprint.md'
    File.read(file)
  end

  def next_task
    # Get the first uncompleted task
    @my_tasks.first
  end

  def work
    puts "My assigned tasks:"
    @my_tasks.each { |task| puts task }

    puts "\nWorking on: #{next_task}"

    # Execute the task
    execute_task(next_task)
  end
end
```

**When you run:**
```bash
claude backend-developer --work
```

**Output:**
```
My assigned tasks:
- [ ] TASK-001: Create migration for recurring_bookings table (2h)
- [ ] TASK-002: Create RecurringBooking model with validations (3h)
- [ ] TASK-003: Add associations to Booking model (1h)
...

Working on: TASK-001: Create migration for recurring_bookings table
```

#### Step 6: Backend Developer Executes Task

```ruby
# backend-developer skill executes
def execute_task(task)
  if task.include?('Create migration')
    # Generate Rails migration
    system('bin/rails generate migration CreateRecurringBookings ...')

    # Mark task complete
    complete_task('TASK-001')
  end
end

def complete_task(task_id)
  # Update assigned.md file
  file = '.claude/backlog/tasks/backend/assigned.md'
  content = File.read(file)

  # Change [ ] to [x]
  updated = content.gsub(
    "- [ ] #{task_id}:",
    "- [x] #{task_id}:"
  )

  File.write(file, updated)

  puts "✅ Task #{task_id} completed"

  # Check if all tasks for story are done
  story_id = task_id.split('-').first(2).join('-')  # e.g., RB-101
  check_story_completion(story_id)
end
```

**File updated: `.claude/backlog/tasks/backend/assigned.md`**
```markdown
# Backend Developer - Assigned Tasks

## Current Sprint (Sprint 16)

### RB-101: Create RecurringBooking Model
- [x] TASK-001: Create migration for recurring_bookings table (2h) ✅
- [ ] TASK-002: Create RecurringBooking model with validations (3h)
- [ ] TASK-003: Add associations to Booking model (1h)
- [ ] TASK-004: Write unit tests for RecurringBooking (2h)
```

#### Step 7: Story Completion Check

```ruby
def check_story_completion(story_id)
  # Count completed tasks for this story
  tasks = @my_tasks.select { |t| t.include?(story_id) }
  completed = tasks.count { |t| t.start_with?('- [x]') }
  total = tasks.count

  if completed == total
    # All tasks done! Update story status
    update_story_status(story_id, 'Review')

    puts "✅ All tasks completed for #{story_id}"
    puts "📝 Story moved to Review"

    # Notify QA tester
    notify_skill('qa-tester', "#{story_id} ready for testing")
  else
    puts "📊 Progress: #{completed}/#{total} tasks completed"
  end
end
```

**File updated: `.claude/backlog/user-stories/RB-101-create-recurring.md`**
```markdown
# User Story: Create RecurringBooking Model

**Story ID**: RB-101
**Status**: Review  ← Changed from "In Progress"
**Assigned To**: backend-developer

## Tasks
- [x] TASK-001: Create migration (2h) ✅
- [x] TASK-002: Create model (3h) ✅
- [x] TASK-003: Add associations (1h) ✅
- [x] TASK-004: Write tests (2h) ✅

Completed: 2026-02-28
```

#### Step 8: QA Tester Notified

```ruby
# qa-tester skill receives notification
class QaTester
  def initialize
    @notifications = check_notifications
  end

  def check_notifications
    # Check for stories in "Review" status assigned to QA
    Dir.glob('.claude/backlog/user-stories/*.md').select do |file|
      content = File.read(file)
      content.include?('Status: Review') &&
      content.include?('Needs: QA Testing')
    end
  end

  def work
    @notifications.each do |story_file|
      story_id = File.basename(story_file, '.md').split('-').first(2).join('-')

      puts "📋 Testing #{story_id}..."

      # Run tests
      run_tests_for_story(story_id)
    end
  end
end
```

#### Step 9: Sprint Completion

When all stories in sprint are done:

```ruby
# project-manager skill tracks sprint
class ProjectManager
  def check_sprint_completion
    sprint = load_current_sprint

    stories = sprint.scan(/- \[ \] \*\*(.*?)\*\*/)
    completed = sprint.scan(/- \[x\] \*\*(.*?)\*\*/)

    if stories.count == completed.count
      puts "🎉 Sprint completed!"

      # Archive sprint
      archive_sprint

      # Generate sprint report
      generate_sprint_report

      # Notify team
      notify_team("Sprint 16 completed!")
    end
  end
end
```

#### Step 10: MVP Release

When multiple sprints are done, release to production:

```bash
# Trigger MVP release
bin/rails runner "MvpReleaseConductor.new(version: 'v1.1.0').release!"
```

**MVP Release Conductor:**
1. Reads all completed stories since last release
2. Runs automated tests
3. Deploys to production
4. Generates release report including all features released

## Summary: How Skills Know What to Work On

### 1. **Work Intake**
- Product Owner or Work Intake Manager creates stories
- Stories broken into tasks
- Tasks assigned to appropriate skills

### 2. **File-Based Task Assignment**
```
.claude/backlog/tasks/backend/assigned.md    ← backend-developer reads this
.claude/backlog/tasks/frontend/assigned.md   ← frontend-developer reads this
.claude/backlog/tasks/testing/assigned.md    ← qa-tester reads this
```

### 3. **Skills Auto-Load Work**
Every skill has:
```ruby
def initialize
  @my_tasks = load_assigned_tasks  # Reads their assigned.md file
end

def next_task
  @my_tasks.find { |t| t.start_with?('- [ ]') }  # First uncompleted
end
```

### 4. **Skills Execute & Update**
```ruby
def execute_task(task)
  # Do the work (generate code, run tests, etc.)
  perform_work(task)

  # Mark complete
  update_file(task, '- [ ]' => '- [x]')

  # Notify next skill if needed
  notify_next_skill
end
```

### 5. **Coordination**
- MVP Release Conductor orchestrates multiple skills
- Project Manager tracks overall progress
- Product Owner reprioritizes as needed

## Quick Commands

```bash
# View what's assigned to backend
cat .claude/backlog/tasks/backend/assigned.md

# View current sprint
cat .claude/backlog/sprints/current-sprint.md

# Add new feature (creates stories + tasks automatically)
bin/rails runner "WorkIntakeManager.new.intake_feature_request('description')"

# Backend developer works on next task
claude backend-developer --work

# Check sprint progress
claude project-manager --sprint-status

# Release MVP when ready
claude mvp-release-conductor --release-mvp --version v1.0.0
```

## The Magic ✨

**Skills are autonomous because:**
1. ✅ They know where to find their work (assigned.md files)
2. ✅ They know what to do (detailed task descriptions)
3. ✅ They know the order (priority in file)
4. ✅ They update their status (mark tasks complete)
5. ✅ They notify others (when work is ready for next skill)

**You just need to:**
1. Add feature requests → Work Intake Manager handles the rest
2. Prioritize stories → Product Owner decides what's next
3. Trigger skills → They read their assignments and work
4. Release MVP → Release Conductor orchestrates everything

🎯 **It's like having an autonomous development team that manages itself!**
