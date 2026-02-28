# 🚀 Start Development - Quick Reference

**Last Updated**: February 28, 2026
**Status**: Ready to Begin Sprint 17
**Next Sprint Starts**: March 3, 2026

---

## ⚡ Quick Start Prompts

### Option 1: Start Sprint 17 (Preventive Maintenance)
```
Start Sprint 17: Preventive Maintenance. Review the sprint plan at
.claude/backlog/sprints/sprint-17-preventive-maintenance.md and begin
working on MAINT-101 (Schedule Recurring Maintenance). Use the
backend-developer skill to implement the MaintenanceSchedule model
and associated functionality.
```

### Option 2: Pick a Specific User Story
```
Implement user story MAINT-101 from .claude/backlog/user-stories/MAINT-101-schedule-recurring-maintenance.md
Use the backend-developer skill to create the database migration, model,
service layer, and API endpoints as specified in the story.
```

### Option 3: Review and Prioritize
```
Review the product roadmap at .claude/backlog/PRODUCT_ROADMAP.md and
the feature inventory at .claude/backlog/FEATURE_INVENTORY.md.
Help me decide which epic to prioritize based on current business needs.
```

### Option 4: Work on Technical Debt
```
Review the technical debt log at .claude/backlog/TECHNICAL_DEBT.md and
work on TD-002 (Add Database Indexes for Performance). Use the
database-administrator skill to identify slow queries and add appropriate indexes.
```

### Option 5: Continue Current Sprint
```
Check the current sprint at .claude/backlog/sprints/current-sprint.md
and continue work on the highest priority incomplete story. Update the
sprint progress as work is completed.
```

---

## 📋 Development Workflow

### Step 1: Choose Your Starting Point

**Option A - Follow the Roadmap** (Recommended)
- Start with Sprint 17 (Preventive Maintenance)
- Highest business value, no dependencies
- Clear user stories already written

**Option B - Fix Technical Debt**
- Address performance issues first
- Build solid foundation for new features
- Improves developer experience

**Option C - Build What Interests You**
- Pick any epic that excites you
- Review epic files in `.claude/backlog/epics/`
- Self-directed development

### Step 2: Assign to the Right Skill

| Epic | Primary Skill | Supporting Skills |
|------|---------------|-------------------|
| MAINT | backend-developer | qa-tester, devops-engineer |
| FIN | backend-developer | database-administrator |
| CAL | backend-developer | frontend-developer |
| EMAIL | backend-developer | - |
| ROUTE | backend-developer | devops-engineer |
| MOBILE | (need to hire) | backend-developer (API work) |
| POD | frontend-developer | backend-developer |

### Step 3: Track Progress

Use the sprint files to track daily progress:
```bash
# Mark a story as in progress
# Edit .claude/backlog/sprints/sprint-17-preventive-maintenance.md
# Change: - [ ] **MAINT-101**
# To:     - [🔄] **MAINT-101** (In Progress - Day 1)

# Mark complete
# Change: - [🔄] **MAINT-101**
# To:     - [x] **MAINT-101** (Completed - Day 3)
```

---

## 🎯 Recommended Starting Prompts by Role

### For Product Work
```
Act as product-manager skill. Review the FEATURE_INVENTORY.md and
create 5 additional user stories for the FIN epic (Financial Reporting).
Each story should follow the template and include acceptance criteria,
database changes, API endpoints, and task breakdown.
```

### For Backend Development
```
Use backend-developer skill to implement MAINT-101. Start by creating
the migration for the maintenance_schedules table, then create the
MaintenanceSchedule model with validations and associations. Follow
the technical specifications in the user story.
```

### For Database Work
```
Use database-administrator skill to analyze the current database schema
and recommend indexes for the top 10 most frequently queried tables.
Focus on foreign keys, timestamp columns, and status/state columns.
```

### For Testing
```
Use qa-tester skill to create comprehensive RSpec tests for the
MaintenanceSchedule model once it's implemented. Include unit tests
for validations, associations, and business logic methods.
```

### For DevOps
```
Use devops-engineer skill to set up monitoring for the production
database. Configure alerts for slow queries, high CPU usage, and
connection pool exhaustion. Document the monitoring setup.
```

---

## 📂 Key Files to Reference

### Backlog Structure
```
.claude/backlog/
├── FEATURE_INVENTORY.md          ← What's built vs. what's missing
├── PRODUCT_ROADMAP.md             ← 4-phase strategic plan
├── BACKLOG_SUMMARY.md             ← Executive summary
├── TECHNICAL_DEBT.md              ← Tech debt prioritization
├── QUICK_START_GUIDE.md           ← How skills use the backlog
│
├── epics/                         ← 12 epic files
│   ├── MAINT-preventive-maintenance.md
│   ├── FIN-financial-reporting.md
│   └── ...
│
├── user-stories/                  ← Detailed implementation specs
│   ├── MAINT-101-schedule-recurring-maintenance.md
│   ├── FIN-101-profit-loss-statement.md
│   └── ...
│
└── sprints/                       ← Sprint planning
    ├── sprint-17-preventive-maintenance.md
    ├── sprint-18-financial-reporting.md
    └── sprint-19-calendar-email-automation.md
```

### Quick Navigation
```bash
# See what's already built
cat .claude/backlog/FEATURE_INVENTORY.md | grep "✅"

# See what's missing
cat .claude/backlog/FEATURE_INVENTORY.md | grep "❌"

# View next sprint
cat .claude/backlog/sprints/sprint-17-preventive-maintenance.md

# Read a user story
cat .claude/backlog/user-stories/MAINT-101-schedule-recurring-maintenance.md

# Check technical debt
cat .claude/backlog/TECHNICAL_DEBT.md
```

---

## 🎬 Sample Complete Prompts

### 1. Start Preventive Maintenance Feature (Recommended First)
```
I want to implement the preventive maintenance system. Use the
backend-developer skill to work through user story MAINT-101 from
.claude/backlog/user-stories/MAINT-101-schedule-recurring-maintenance.md

Follow these steps:
1. Create the migration for maintenance_schedules table
2. Create the MaintenanceSchedule model with validations
3. Create the MaintenanceScheduleService
4. Add API endpoints to MaintenanceJobsController
5. Write RSpec tests
6. Update the sprint progress in sprint-17-preventive-maintenance.md

Work autonomously and ask for review when the story is complete.
```

### 2. Build Financial Reporting (P&L Statement)
```
Implement the Profit & Loss statement feature. Use backend-developer skill
to work on FIN-101 from .claude/backlog/user-stories/FIN-101-profit-loss-statement.md

Create:
1. ProfitLossReport model/service
2. Expense tracking model
3. Chart of accounts (simple)
4. API endpoint: GET /api/v1/reports/profit_loss
5. Tests for all calculations

Refer to existing Revenue report logic in app/services/ for patterns.
```

### 3. Add Google Calendar Integration
```
Implement Google Calendar sync. Use backend-developer skill for CAL-101
from .claude/backlog/user-stories/CAL-101-google-calendar-sync.md

Requirements:
1. OAuth 2.0 setup (Google Cloud Console)
2. CalendarSync model for storing tokens
3. GoogleCalendarService for API calls
4. Two-way sync (Rentable → Google and Google → Rentable)
5. Webhook handling for Google Calendar changes
6. Token refresh logic

Start with OAuth setup and token storage.
```

### 4. Setup Email Marketing Automation
```
Build the email campaign system. Use backend-developer skill for EMAIL-101
from .claude/backlog/user-stories/EMAIL-101-quote-follow-up-automation.md

Create:
1. EmailCampaign model (drip sequences)
2. EmailCampaignEmail model (individual emails in sequence)
3. SendGrid integration service
4. Background job: SendCampaignEmailsJob
5. Tracking for opens/clicks/conversions
6. 3-email quote follow-up sequence (Day 1, Day 3, Day 7)

Integrate with existing Quote system.
```

### 5. Fix Technical Debt (Database Performance)
```
Use database-administrator skill to work on TD-002 from
.claude/backlog/TECHNICAL_DEBT.md

Analyze slow queries and add missing indexes:
1. Run EXPLAIN ANALYZE on common queries
2. Identify missing indexes on foreign keys
3. Add composite indexes for common filters
4. Create migration with all index additions
5. Document query performance improvements

Focus on: bookings, booking_line_items, products, product_instances
```

---

## 🔄 Sprint Workflow

### Daily Development Pattern

**Morning** (Planning)
```
Review current sprint progress and pick the next highest priority task
from .claude/backlog/sprints/sprint-17-preventive-maintenance.md
```

**During Development** (Execution)
```
Use [skill-name] to implement [story-id]. Follow the acceptance criteria
and technical specifications in the user story. Update progress in the
sprint file as you complete tasks.
```

**End of Day** (Review)
```
Update sprint progress in sprint-17-preventive-maintenance.md. Mark
completed tasks with [x] and add notes on any blockers. If a story is
complete, mark it done and move to the next story.
```

### Sprint Planning Pattern

**Every 2 Weeks**
```
Review completed sprint at .claude/backlog/sprints/sprint-[N].md
Calculate velocity (points completed)
Plan next sprint based on team capacity and roadmap priorities
Create new sprint file: sprint-[N+1].md
```

---

## 💡 Tips for Effective Development

### 1. Start Small
- Pick ONE user story
- Complete it fully (code + tests + docs)
- Mark it done
- Then move to the next

### 2. Use the Skills
- Don't code everything yourself
- Delegate to specialized skills (backend-developer, qa-tester, etc.)
- Let skills work autonomously

### 3. Follow the Roadmap
- Phase 1 (Q2 2026) priorities are validated
- Don't skip ahead to Phase 3 features
- Business value decreases as you move down the list

### 4. Update as You Go
- Keep sprint files current
- Mark stories complete when done
- Add new stories as you discover them

### 5. Balance Features and Tech Debt
- 80% feature development
- 20% technical debt reduction
- Don't let debt accumulate

---

## 🆘 If You Get Stuck

### "I don't know what to work on"
→ Read `.claude/backlog/PRODUCT_ROADMAP.md` Phase 1
→ Start with MAINT-101 (preventive maintenance)

### "I need more detail on a feature"
→ Read the user story in `.claude/backlog/user-stories/`
→ Read the epic in `.claude/backlog/epics/`
→ Check the feature inventory for related existing features

### "I don't know if something is already built"
→ Read `.claude/backlog/FEATURE_INVENTORY.md`
→ Search the codebase: `grep -r "feature_name" app/`

### "The sprint plan is too long"
→ Pick just ONE story from the sprint
→ Complete it fully before moving on

### "I want to build something else"
→ That's fine! This is your project
→ Just document what you build
→ Update the backlog accordingly

---

## ✅ Success Criteria

You'll know you're making good progress when:

1. **Sprint Progress**: Stories moving from [ ] → [🔄] → [x]
2. **Tests Passing**: RSpec suite stays green
3. **API Working**: Can test endpoints with `curl`
4. **Documentation Updated**: README and API docs reflect new features
5. **Velocity Stable**: Completing 40-60 points per 2-week sprint

---

## 🎯 Immediate Next Steps

### Choose ONE of these prompts to start:

**A. Follow the Plan** (Recommended)
```
Start Sprint 17. Implement MAINT-101 using backend-developer skill.
Create the MaintenanceSchedule model and associated functionality as
specified in .claude/backlog/user-stories/MAINT-101-schedule-recurring-maintenance.md
```

**B. Quick Win**
```
Fix technical debt TD-002 using database-administrator skill. Add missing
database indexes to improve query performance. Focus on bookings and
products tables.
```

**C. Explore First**
```
Use product-manager skill to review the FEATURE_INVENTORY.md and
PRODUCT_ROADMAP.md. Provide a summary of the top 3 most impactful
features we should build next and why.
```

---

**Ready to build? Copy one of the prompts above and let's start! 🚀**
