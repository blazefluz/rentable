# Work Intake Manager

Manages the flow of work into the product backlog, ensuring all features, bugs, and tasks are properly documented, prioritized, and assigned to the right skills.

## Description

This skill acts as the **work intake coordinator** that:
- Captures new feature requests and converts them to user stories
- Triages bugs and technical debt
- Breaks down large initiatives into epics and stories
- Assigns work to appropriate specialist skills
- Maintains the product backlog
- Ensures work is ready before adding to sprint
- Tracks dependencies and blockers

**Think of this as your AI Product Coordinator** that ensures every piece of work is properly defined before developers start working on it.

## When to Use

Use this skill when you need to:
- Add a new feature request to the backlog
- Create user stories from requirements
- Break down an epic into manageable stories
- Assign stories to skills (backend, frontend, QA, etc.)
- Prioritize the backlog
- Prepare stories for sprint planning
- Track feature requests from stakeholders

## Quick Start

### 1. Add New Feature Request

```bash
# Single command to capture a feature request
claude work-intake-manager --new-feature "Users should be able to create recurring bookings"

# This automatically:
# 1. Creates epic file
# 2. Generates user stories
# 3. Breaks into tasks
# 4. Assigns to appropriate skills
# 5. Adds to backlog
```

### 2. Create User Story from Template

```bash
bin/rails runner <<'RUBY'
require 'work_intake_manager'

manager = WorkIntakeManager.new

story = manager.create_story(
  title: "Create Recurring Booking",
  epic: "recurring-bookings",
  as_a: "rental company manager",
  i_want_to: "create recurring bookings that repeat weekly",
  so_that: "I don't have to manually create each week's booking",
  points: 8
)

# Output:
# ✅ Story created: RB-101-create-recurring-booking.md
# 📝 6 backend tasks assigned to backend-developer
# 📝 2 testing tasks assigned to qa-tester
# 📊 Added to backlog with 8 story points
RUBY
```

### 3. Assign Work for Current Sprint

```bash
bin/rails runner <<'RUBY'
manager = WorkIntakeManager.new

# Assign stories to current sprint
manager.plan_sprint(
  sprint_number: 16,
  capacity: { 'backend-developer' => 16, 'frontend-developer' => 16 },
  stories: ['PRICE-101', 'PRICE-102', 'PRICE-103', 'BUG-045']
)

# Output:
# ✅ Sprint 16 planned
# 📊 30 points committed (54% capacity)
# 👥 backend-developer: 13 pts assigned
# 👥 frontend-developer: 12 pts assigned
# 📝 Updated .claude/backlog/sprints/current-sprint.md
RUBY
```

## Core Responsibilities

### 1. Feature Request Intake

Capture new feature requests and convert to structured work items:

```ruby
class WorkIntakeManager
  def intake_feature_request(description)
    # Parse natural language request
    parsed = parse_request(description)

    # Determine if it's an epic or single story
    if parsed[:complexity] > 13  # Story points
      create_epic(parsed)
    else
      create_story(parsed)
    end

    # Auto-assign to appropriate skills
    assign_to_skills(parsed)

    # Add to backlog with initial priority
    add_to_backlog(parsed, priority: 'Medium')
  end
end
```

**Example**:

```bash
bin/rails runner <<'RUBY'
manager = WorkIntakeManager.new

# Capture feature request
manager.intake_feature_request(
  "We need a customer self-service portal where customers can log in,
   view their bookings, make new bookings, and pay online.
   This should integrate with Stripe for payments."
)

# Output:
# 📋 Analyzing request...
# ✅ Created Epic: customer-portal
# 📝 Generated 5 user stories:
#   - PORTAL-101: Customer authentication (5 pts)
#   - PORTAL-102: Customer dashboard (8 pts)
#   - PORTAL-103: Self-service booking (13 pts)
#   - PORTAL-104: Payment integration (8 pts)
#   - PORTAL-105: Booking history (5 pts)
# 👥 Assigned to:
#   - backend-developer: 4 stories (20 pts)
#   - frontend-developer: 5 stories (15 pts)
#   - devops-engineer: 1 story (3 pts)
# 📊 Total: 39 story points (~2 sprints)
RUBY
```

### 2. Bug Triage

Prioritize and assign bug fixes:

```ruby
def triage_bug(bug_report)
  # Determine severity
  severity = assess_severity(bug_report)

  # Auto-prioritize based on severity
  priority = case severity
  when :critical then 'P0 - Fix immediately'
  when :high     then 'P1 - Fix this sprint'
  when :medium   then 'P2 - Fix next sprint'
  when :low      then 'P3 - Backlog'
  end

  # Assign to appropriate skill
  skill = determine_skill_from_bug(bug_report)

  create_bug_story(
    title: bug_report[:title],
    severity: severity,
    priority: priority,
    assigned_to: skill,
    points: estimate_bug_effort(severity)
  )
end
```

**Example**:

```bash
bin/rails runner <<'RUBY'
manager = WorkIntakeManager.new

manager.triage_bug(
  title: "Line item tax calculation incorrect with weekend pricing",
  description: "When a booking spans a weekend, the tax calculation is wrong...",
  steps_to_reproduce: "1. Create booking for Sat-Mon...",
  expected: "Tax should calculate on total including weekend premium",
  actual: "Tax only calculates on base price",
  severity: :high
)

# Output:
# 🐛 Bug triaged: BUG-045
# 🔴 Severity: High
# ⚡ Priority: P1 - Fix this sprint
# 👤 Assigned to: backend-developer
# 📊 Estimated: 5 story points
# 📝 Created: .claude/backlog/user-stories/BUG-045-tax-calculation.md
# ✅ Added to current sprint (high priority)
RUBY
```

### 3. Epic Breakdown

Break large features into manageable stories:

```ruby
def break_down_epic(epic_name, epic_description)
  # Create epic file
  epic = create_epic_file(epic_name, epic_description)

  # Generate user stories using AI/templates
  stories = generate_stories_from_epic(epic)

  # Create story files
  stories.each do |story|
    create_story_file(
      story_id: "#{epic[:id]}-#{story[:number]}",
      title: story[:title],
      epic: epic_name,
      description: story[:description],
      acceptance_criteria: story[:acceptance_criteria],
      points: story[:points]
    )
  end

  # Generate dependency graph
  create_dependency_map(stories)

  # Calculate total effort
  total_points = stories.sum { |s| s[:points] }
  estimated_sprints = (total_points / 30.0).ceil

  puts "Epic breakdown complete:"
  puts "  Stories: #{stories.count}"
  puts "  Total points: #{total_points}"
  puts "  Estimated duration: #{estimated_sprints} sprints"
end
```

**Example**:

```bash
bin/rails runner <<'RUBY'
manager = WorkIntakeManager.new

manager.break_down_epic(
  'recurring-bookings',
  'Allow customers to create bookings that repeat on a schedule
   (daily, weekly, monthly) with automatic generation'
)

# Output:
# 📋 Epic: recurring-bookings
# ✅ Created 6 user stories:
#
# 1. RB-101: Create RecurringBooking model (5 pts)
#    - Database schema for recurring patterns
#    - Validations and associations
#    Dependencies: None
#
# 2. RB-102: Background job for booking generation (8 pts)
#    - Sidekiq job to generate bookings
#    - Cron schedule integration
#    Dependencies: RB-101
#
# 3. RB-103: Recurring booking API endpoints (5 pts)
#    - CRUD endpoints for recurring bookings
#    Dependencies: RB-101
#
# 4. RB-104: Recurring booking UI (8 pts)
#    - Form to create/edit recurring bookings
#    - Calendar preview
#    Dependencies: RB-103
#
# 5. RB-105: Availability checking (8 pts)
#    - Check availability for all occurrences
#    - Prevent conflicts
#    Dependencies: RB-102
#
# 6. RB-106: Testing & documentation (3 pts)
#    - Full test coverage
#    - User documentation
#    Dependencies: RB-101, RB-102, RB-103, RB-104, RB-105
#
# 📊 Total: 37 story points
# 📅 Estimated: 2 sprints
# 👥 Assigned:
#    - backend-developer: 18 pts (4 stories)
#    - frontend-developer: 16 pts (2 stories)
#    - qa-tester: 3 pts (1 story)
RUBY
```

### 4. Assign Work to Skills

Intelligently assign stories to the right specialist skills:

```ruby
def assign_story_to_skill(story)
  # Analyze story content to determine skill needed
  skills_needed = []

  if story[:tasks].any? { |t| t.include?('model') || t.include?('API') }
    skills_needed << 'backend-developer'
  end

  if story[:tasks].any? { |t| t.include?('UI') || t.include?('component') }
    skills_needed << 'frontend-developer'
  end

  if story[:tasks].any? { |t| t.include?('test') || t.include?('QA') }
    skills_needed << 'qa-tester'
  end

  if story[:tasks].any? { |t| t.include?('deploy') || t.include?('infrastructure') }
    skills_needed << 'devops-engineer'
  end

  # Create task assignments
  skills_needed.each do |skill|
    assign_tasks_to_skill(story, skill)
  end
end

def assign_tasks_to_skill(story, skill_name)
  # Append to skill's assigned tasks file
  tasks_file = ".claude/backlog/tasks/#{skill_type(skill_name)}/assigned.md"

  relevant_tasks = story[:tasks].select do |task|
    task[:assigned_to] == skill_name
  end

  File.open(tasks_file, 'a') do |f|
    relevant_tasks.each do |task|
      f.puts "- [ ] #{story[:id]}: #{task[:description]} (#{task[:estimate]})"
    end
  end

  puts "✅ Assigned #{relevant_tasks.count} tasks to #{skill_name}"
end
```

### 5. Backlog Grooming

Keep the backlog healthy and up-to-date:

```ruby
def groom_backlog
  puts "🧹 Grooming backlog..."

  # 1. Remove completed stories from active backlog
  archive_completed_stories

  # 2. Re-prioritize based on business value
  reprioritize_stories

  # 3. Ensure top stories are "ready"
  ensure_stories_ready_for_sprint

  # 4. Identify and flag blockers
  identify_blockers

  # 5. Update estimates if needed
  review_estimates

  # 6. Check for stale stories (>90 days in backlog)
  flag_stale_stories

  puts "✅ Backlog groomed"
end

def ensure_stories_ready_for_sprint
  top_stories = get_top_backlog_stories(10)

  top_stories.each do |story|
    ready = check_story_ready(story)

    unless ready[:is_ready]
      puts "⚠️  #{story[:id]} not ready:"
      ready[:missing].each { |item| puts "  - Missing: #{item}" }
    end
  end
end

def check_story_ready(story)
  missing = []

  missing << "Acceptance criteria" if story[:acceptance_criteria].empty?
  missing << "Story points" if story[:points].nil?
  missing << "Tasks breakdown" if story[:tasks].empty?
  missing << "Dependencies identified" if story[:dependencies].nil?

  { is_ready: missing.empty?, missing: missing }
end
```

## Real-World Usage Examples

### Example 1: Stakeholder Feature Request

```bash
# Stakeholder sends email: "We need customers to be able to create
# recurring bookings for their weekly equipment rentals"

bin/rails runner <<'RUBY'
manager = WorkIntakeManager.new

# Capture the request
epic = manager.intake_feature_request(
  "Customers need to create recurring bookings for weekly rentals.
   The system should automatically generate bookings based on a schedule
   (daily, weekly, monthly). Customers should see a preview of all
   generated bookings before confirming."
)

# Output shows:
# ✅ Epic created: recurring-bookings
# 📝 6 user stories generated
# 📊 37 story points total
# 📅 Estimated: 2 sprints
# 👥 Tasks assigned to backend-developer, frontend-developer, qa-tester
# 📋 Added to product backlog
#
# Next steps:
#   1. Product Owner: Review and prioritize stories
#   2. Tech Lead: Review technical approach
#   3. Team: Estimate during planning poker
RUBY
```

### Example 2: Bug Report from Customer

```bash
# Customer reports: "Tax calculation is wrong on weekend bookings"

bin/rails runner <<'RUBY'
manager = WorkIntakeManager.new

bug = manager.triage_bug(
  title: "Tax calculation incorrect for weekend bookings",
  description: "When a booking includes weekend days, tax is only calculated on base price, not including weekend premium",
  steps_to_reproduce: [
    "Create booking for Saturday-Monday",
    "Add product with weekend pricing enabled",
    "Check total price and tax"
  ],
  expected: "Tax should calculate on $540 + $500 = $1,040",
  actual: "Tax calculates on $750 only",
  severity: :high,
  reported_by: "customer@example.com"
)

# Output:
# 🐛 BUG-045: Tax calculation incorrect for weekend bookings
# 🔴 Severity: High
# ⚡ Priority: P1 - Fix this sprint
# 👤 Assigned to: backend-developer
# 📊 Estimated: 5 story points
# ✅ Added to Sprint 16 (high priority)
# 📧 Email sent to customer: "We're working on this, ETA: Feb 14"
RUBY
```

### Example 3: Sprint Planning

```bash
# Product Owner prepares for Sprint 16 planning

bin/rails runner <<'RUBY'
manager = WorkIntakeManager.new

# Get team capacity
team_capacity = {
  'backend-developer' => 16,
  'frontend-developer' => 16,
  'qa-tester' => 12,
  'devops-engineer' => 10
}

# Product Owner's priority list
priority_stories = [
  'PRICE-101',  # Dynamic pricing engine (8 pts)
  'PRICE-102',  # Weekend pricing (5 pts)
  'BUG-045',    # Tax bug (5 pts - HIGH PRIORITY)
  'PRICE-103',  # Discount automation (5 pts)
  'TECH-08'     # Performance optimization (2 pts)
]

# Plan the sprint
sprint = manager.plan_sprint(
  sprint_number: 16,
  sprint_goal: "Implement smart pricing engine",
  capacity: team_capacity,
  stories: priority_stories
)

# Output:
# 📋 Sprint 16 Planning
# 🎯 Sprint Goal: Implement smart pricing engine
#
# Team Capacity:
#   backend-developer: 16 points
#   frontend-developer: 16 points
#   qa-tester: 12 points
#   devops-engineer: 10 points
#   TOTAL: 54 points
#
# Committed Stories:
#   ✅ PRICE-101 (8 pts) → backend-developer
#   ✅ PRICE-102 (5 pts) → backend-developer
#   ✅ BUG-045 (5 pts) → backend-developer (HIGH PRIORITY)
#   ✅ PRICE-103 (5 pts) → backend-developer
#   ✅ TECH-08 (2 pts) → devops-engineer
#
# Sprint Summary:
#   Committed: 25 points (46% capacity)
#   Remaining capacity: 29 points
#   Utilization: Healthy (not overcommitted)
#
# Task Assignments:
#   ✅ 18 tasks → backend-developer/assigned.md
#   ✅ 5 tasks → qa-tester/assigned.md
#   ✅ 2 tasks → devops-engineer/assigned.md
#
# 📝 Updated files:
#   - .claude/backlog/sprints/sprint-16.md
#   - .claude/backlog/sprints/current-sprint.md (symlink)
#   - .claude/backlog/tasks/backend/assigned.md
#   - .claude/backlog/tasks/testing/assigned.md
#   - .claude/backlog/tasks/devops/assigned.md
RUBY
```

### Example 4: Daily Backlog Grooming

```bash
# Run daily to keep backlog healthy

bin/rails runner <<'RUBY'
manager = WorkIntakeManager.new

grooming_results = manager.groom_backlog

# Output:
# 🧹 Grooming backlog...
#
# ✅ Archived 8 completed stories to /completed/sprint-15/
# ✅ Re-prioritized 15 stories based on business value
# ⚠️  3 stories not ready for sprint:
#     - PORTAL-103: Missing acceptance criteria
#     - PRICE-105: No story points estimated
#     - RB-107: Dependencies not identified
# 🔴 2 blockers identified:
#     - PRICE-102: Waiting for holiday calendar data (Product Owner)
#     - PORTAL-104: Stripe test keys needed (DevOps)
# 📊 5 stories flagged as stale (>90 days in backlog)
# ✅ Backlog groomed
#
# Next actions:
#   - Product Owner: Provide acceptance criteria for PORTAL-103
#   - Team: Estimate PRICE-105 in next planning
#   - Product Owner: Provide holiday calendar data
#   - DevOps: Set up Stripe test environment
RUBY
```

## Integration with Skills

All specialist skills check their assigned work:

```ruby
# In backend-developer skill
class BackendDeveloper
  def initialize
    @work_manager = WorkIntakeManager.new
    @my_tasks = load_my_tasks
  end

  def load_my_tasks
    # Read assigned tasks
    tasks_file = '.claude/backlog/tasks/backend/assigned.md'
    tasks = File.read(tasks_file)

    # Parse uncompleted tasks
    tasks.lines.select { |line| line.start_with?('- [ ]') }
  end

  def next_task
    # Get highest priority uncompleted task
    @my_tasks.first
  end

  def complete_task(task_id)
    # Mark task complete
    update_task_status(task_id, 'complete')

    # Update story status
    story_id = task_id.split(':').first
    update_story_status(story_id)

    # Notify work manager
    @work_manager.task_completed(task_id, 'backend-developer')
  end
end
```

## Commands for Work Intake

```bash
# Add new feature
claude work-intake-manager --new-feature "Description here"

# Triage bug
claude work-intake-manager --new-bug "Bug description" --severity high

# Break down epic
claude work-intake-manager --break-down-epic "epic-name"

# Plan sprint
claude work-intake-manager --plan-sprint 16

# Groom backlog
claude work-intake-manager --groom-backlog

# View backlog
cat .claude/backlog/README.md
```

## Automation

Work intake manager can run automatically:

```yaml
# .github/workflows/backlog-grooming.yml
name: Daily Backlog Grooming

on:
  schedule:
    - cron: '0 9 * * *'  # 9 AM daily

jobs:
  groom:
    runs-on: ubuntu-latest
    steps:
      - name: Groom backlog
        run: |
          bin/rails runner "
            manager = WorkIntakeManager.new
            manager.groom_backlog
          "
```

## Related Skills

- [product-owner](../product-owner/skill.md) - Owns product backlog and prioritization
- [project-manager](../project-manager/skill.md) - Sprint planning and tracking
- [backend-developer](../backend-developer/skill.md) - Executes backend tasks
- [frontend-developer](../frontend-developer/skill.md) - Executes frontend tasks
- [qa-tester](../qa-tester/skill.md) - Executes testing tasks
- [devops-engineer](../devops-engineer/skill.md) - Executes infrastructure tasks

## Best Practices

1. **Capture everything** - Never lose a feature request or bug report
2. **Break work down** - Stories should be <13 points, tasks <4 hours
3. **Assign clearly** - Every story has an owner
4. **Keep backlog groomed** - Review and clean up weekly
5. **Make work ready** - Stories should be "ready" before sprint
6. **Track dependencies** - Know what blocks what
7. **Estimate properly** - Use planning poker for accuracy
8. **Archive completed work** - Keep backlog focused on future work

This skill ensures your development team always knows what to work on next! 🎯
