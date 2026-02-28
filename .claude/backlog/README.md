# Product Backlog for Rentable MVP

This directory contains the **product backlog** - all features, user stories, and tasks that skills need to work on.

## How Skills Know What to Work On

```
1. Product Owner creates user stories → stored in backlog/
2. Skills read backlog to see what's assigned to them
3. Skills execute tasks and update status
4. Product Owner reviews completed work
```

## Directory Structure

```
.claude/backlog/
├── README.md (this file)
├── epics/               # High-level features
│   ├── recurring-bookings.md
│   ├── smart-pricing.md
│   └── customer-portal.md
├── user-stories/        # Detailed user stories
│   ├── RB-101-create-recurring-booking.md
│   ├── PRICE-102-weekend-pricing.md
│   └── ...
├── sprints/             # Sprint backlogs
│   ├── sprint-15.md
│   ├── sprint-16.md
│   └── current-sprint.md (symlink)
├── tasks/               # Granular tasks
│   ├── backend/
│   ├── frontend/
│   ├── devops/
│   └── testing/
└── completed/           # Archive of done work
    ├── sprint-14/
    └── sprint-13/
```

## Quick Start

### 1. View Current Sprint

```bash
cat .claude/backlog/sprints/current-sprint.md
```

### 2. View Your Assigned Tasks (as a skill)

```bash
# Backend developer sees their tasks
cat .claude/backlog/tasks/backend/assigned.md

# Frontend developer sees their tasks
cat .claude/backlog/tasks/frontend/assigned.md
```

### 3. Create New User Story

```bash
# Product Owner creates story
cp .claude/backlog/templates/user-story-template.md \
   .claude/backlog/user-stories/NEW-123-feature-name.md

# Edit the file with story details
```

### 4. Assign Story to Sprint

```bash
# Add story ID to current sprint
echo "- [ ] RB-123 Create recurring booking" >> .claude/backlog/sprints/current-sprint.md
```

## Skill Integration

Each skill automatically checks its task list:

```ruby
# In backend-developer skill
class BackendDeveloper
  def initialize
    @tasks = load_assigned_tasks
  end

  def load_assigned_tasks
    # Read .claude/backlog/tasks/backend/assigned.md
    File.read('.claude/backlog/tasks/backend/assigned.md')
  end

  def next_task
    @tasks.lines.find { |line| line.start_with?('- [ ]') }
  end
end
```

## Story States

Stories flow through these states:

```
📋 Backlog → 🎯 Ready → 🔄 In Progress → 👀 Review → ✅ Done
```

- **Backlog**: Not yet prioritized
- **Ready**: Prioritized, ready to work on
- **In Progress**: Currently being developed
- **Review**: Completed, awaiting approval
- **Done**: Accepted and merged

## Example Workflow

### Product Owner:
```bash
# 1. Create epic
echo "# Epic: Recurring Bookings" > .claude/backlog/epics/recurring-bookings.md

# 2. Break into stories
cp .claude/backlog/templates/user-story-template.md \
   .claude/backlog/user-stories/RB-101-create-recurring.md

# 3. Add to sprint
echo "- [ ] RB-101 Create recurring booking (8 pts)" >> .claude/backlog/sprints/sprint-15.md

# 4. Assign to developer
echo "- [ ] RB-101: Create RecurringBooking model" >> .claude/backlog/tasks/backend/assigned.md
```

### Backend Developer Skill:
```bash
# 1. Check assigned tasks
cat .claude/backlog/tasks/backend/assigned.md

# 2. Pick next task
# Reads: "- [ ] RB-101: Create RecurringBooking model"

# 3. Execute task
bin/rails generate model RecurringBooking ...

# 4. Mark complete
sed -i 's/- \[ \] RB-101/- [x] RB-101/' .claude/backlog/tasks/backend/assigned.md

# 5. Update story status
sed -i 's/Status: In Progress/Status: Review/' .claude/backlog/user-stories/RB-101-create-recurring.md
```

## Templates

All templates are in `.claude/backlog/templates/`:

- `epic-template.md` - For large features
- `user-story-template.md` - For individual stories
- `bug-template.md` - For bug fixes
- `task-template.md` - For technical tasks
- `sprint-template.md` - For sprint planning

## Integration with MVP Release Conductor

The release conductor reads the backlog to know what's included in a release:

```ruby
# In MvpReleaseConductor
def features_in_release
  # Read all completed stories since last release
  Dir.glob('.claude/backlog/user-stories/*.md').select do |file|
    content = File.read(file)
    content.include?('Status: Done') &&
    content.include?("Completed: #{Date.today}")
  end
end
```

## Best Practices

1. **One story = One file** - Easier to track and move
2. **Use story IDs** - Format: `[EPIC-ID]-[NUMBER]` (e.g., `RB-101`)
3. **Keep tasks small** - Each task should be <4 hours
4. **Update status regularly** - Skills update as they work
5. **Archive completed work** - Move to `completed/` after sprint
6. **Link related items** - Stories link to epics, tasks link to stories

## Automation

Skills can automatically:
- Read their assigned tasks
- Update task status
- Create new tasks (when they discover sub-tasks)
- Notify when blocked
- Request code review

Example:
```ruby
# backend-developer skill auto-updates
def complete_task(task_id)
  # Mark task done
  update_task_status(task_id, 'done')

  # Update story
  update_story_status(story_id_for(task_id), 'review')

  # Notify QA
  notify_skill('qa-tester', "#{task_id} ready for testing")
end
```

## Querying the Backlog

```bash
# What's in current sprint?
cat .claude/backlog/sprints/current-sprint.md

# What's assigned to backend?
cat .claude/backlog/tasks/backend/assigned.md

# What's blocked?
grep -r "Status: Blocked" .claude/backlog/user-stories/

# What's my velocity?
grep -c "Status: Done" .claude/backlog/completed/sprint-*/
```

## Integration with Skills

Each skill has a `load_work()` method:

```ruby
# backend-developer/skill.md includes:
def load_work
  {
    assigned_tasks: parse_tasks('.claude/backlog/tasks/backend/assigned.md'),
    current_sprint: parse_sprint('.claude/backlog/sprints/current-sprint.md'),
    my_stories: find_stories_for('backend-developer')
  }
end
```

This allows skills to be **autonomous** - they know what to work on without you having to tell them each time!
