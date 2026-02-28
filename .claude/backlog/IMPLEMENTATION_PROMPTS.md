# Implementation Prompts - Top 3 Features

**Date**: February 28, 2026
**Based on**: Product roadmap analysis and business impact assessment
**Priority Order**: EMAIL → MAINT → FIN

---

## 🚀 Feature #1: EMAIL - Email Marketing Automation

### Epic: EMAIL (Sprint 20-21, 31 story points)

**Business Goal**: Increase quote conversion by 20% through automated follow-up sequences

---

### Implementation Prompt

```
Use backend-developer skill to implement Email Marketing Automation (EMAIL epic).

CONTEXT:
- We have email_queues table and infrastructure already built
- We have client_communications log tracking all interactions
- We need SendGrid integration for reliable delivery
- Goal: Automate quote follow-up and customer re-engagement

REQUIREMENTS:

1. EMAIL-101: Quote Follow-up Automation (8 pts)
   - Create EmailCampaign model with:
     - campaign_type: quote_followup, customer_reengagement, booking_reminder
     - status: draft, scheduled, active, paused, completed
     - trigger_conditions (JSONB): when to send
     - delay_hours: time delay between emails in sequence
   - Create EmailSequence model:
     - belongs_to :email_campaign
     - sequence_number (1, 2, 3 for day 1, day 3, day 7)
     - subject_template with {{variables}}
     - body_template with {{variables}}
     - send_delay_hours
   - Implement automatic triggers:
     - Quote sent → schedule 3-day follow-up
     - Quote viewed but not approved → schedule 7-day follow-up
     - Quote expired → schedule re-engagement

2. EMAIL-102: Past Customer Re-engagement (5 pts)
   - Identify dormant customers (no booking in 90+ days)
   - Create re-engagement email with:
     - Personalized product recommendations
     - Special offer (10% discount code)
     - Recent equipment additions
   - Track campaign effectiveness (open rate, click rate, conversion)

3. EMAIL-103: Email Template Builder (8 pts)
   - Create EmailTemplate model with:
     - name, category (quote, booking, reminder, marketing)
     - subject with variable placeholders
     - html_body and text_body
     - variable_schema (JSONB) - list of available variables
   - Variable substitution engine:
     - {{customer_name}}, {{quote_number}}, {{total_price}}
     - {{products_list}}, {{start_date}}, {{end_date}}
     - {{company_name}}, {{company_logo}}, {{company_phone}}
   - Preview functionality before sending

4. EMAIL-104: Customer Segmentation (5 pts)
   - Create ClientSegment model:
     - name, description
     - filter_rules (JSONB): complex conditions
     - auto_update: boolean (dynamic vs static)
   - Segment filters:
     - Lifetime value (> $10k, $5k-10k, < $5k)
     - Booking frequency (monthly, quarterly, annual, one-time)
     - Last booking date
     - Product preferences (camera gear, lighting, audio)
     - Industry/market segment
   - Bulk email to segment capability

5. EMAIL-105: Email Analytics Dashboard (5 pts)
   - Track metrics per campaign:
     - Emails sent, delivered, bounced
     - Open rate, click rate
     - Unsubscribe rate
     - Conversion rate (quote approval, new booking)
     - Revenue attributed
   - API endpoints:
     - GET /api/v1/email_campaigns
     - GET /api/v1/email_campaigns/:id/analytics
     - POST /api/v1/email_campaigns (create campaign)
     - POST /api/v1/email_campaigns/:id/send

6. SendGrid Integration:
   - Install sendgrid-ruby gem
   - Configure API keys (ENV['SENDGRID_API_KEY'])
   - Implement webhook receiver for:
     - Email delivered
     - Email opened
     - Link clicked
     - Email bounced
     - Unsubscribe
   - Create SendGridService class in app/services/
   - Handle email sending via background job

TECHNICAL NOTES:
- Use Sidekiq for async email sending (don't block web requests)
- Store sent emails in email_queues for audit trail
- Implement unsubscribe mechanism (one-click unsubscribe header)
- Add rate limiting (max 100 emails/hour to avoid spam flags)
- Track email_communications in client_communications table

FILES TO CREATE:
- app/models/email_campaign.rb
- app/models/email_sequence.rb
- app/models/email_template.rb
- app/models/client_segment.rb
- app/services/sendgrid_service.rb
- app/jobs/send_email_campaign_job.rb
- app/jobs/process_email_webhook_job.rb
- app/controllers/api/v1/email_campaigns_controller.rb
- app/controllers/api/v1/email_templates_controller.rb
- app/controllers/api/v1/webhooks/sendgrid_controller.rb

MIGRATIONS NEEDED:
- create_email_campaigns
- create_email_sequences
- create_email_templates
- create_client_segments
- add_email_metrics_to_email_queues

TESTING:
- Write RSpec tests for each model
- Test email sending with SendGrid sandbox
- Test webhook processing
- Test variable substitution
- Test segmentation filters

SUCCESS CRITERIA:
- Quote follow-up email sent automatically 3 days after quote created
- Open rate > 40%
- Conversion rate > 10% (quotes approved after email)
- Unsubscribe rate < 2%
- No emails flagged as spam
```

**Estimated Duration**: 5 weeks (Sprint 20-21)
**Story Points**: 31
**Dependencies**: SendGrid account ($15-50/month), Sidekiq for background jobs

---

## 🔧 Feature #2: MAINT - Preventive Maintenance Scheduling

### Epic: MAINT (Sprint 17-18, 39 story points)

**Business Goal**: Reduce equipment failures by 80%, extend asset life by 25%

---

### Implementation Prompt

```
Use backend-developer skill to implement Preventive Maintenance Scheduling (MAINT epic).

CONTEXT:
- We have maintenance_jobs table with basic job tracking
- We need recurring maintenance schedules (daily, weekly, monthly, yearly)
- Goal: Automate maintenance scheduling and prevent equipment failures

REQUIREMENTS:

1. MAINT-101: Schedule Recurring Maintenance (13 pts)
   - Enhance MaintenanceJob model with:
     - is_recurring: boolean
     - recurrence_pattern: daily, weekly, monthly, yearly, custom
     - recurrence_interval: integer (e.g., every 3 months)
     - day_of_week: integer (0-6 for weekly patterns)
     - day_of_month: integer (1-31 for monthly patterns)
     - next_occurrence_date: date (calculated)
     - last_generated_date: date
     - auto_generate: boolean (automatically create next job)
   - Create MaintenanceSchedule model:
     - belongs_to :product (or :product_instance)
     - maintenance_type: routine, inspection, calibration, cleaning, lubrication
     - frequency_type: usage_based, time_based
     - frequency_value: integer (e.g., every 100 hours or 30 days)
     - last_maintenance_date: date
     - next_due_date: date
     - estimated_duration_hours: decimal
     - required_parts: jsonb
     - procedure_notes: text
   - Implement GenerateRecurringMaintenanceJob:
     - Runs daily via cron
     - Finds all schedules where next_due_date <= today + 7 days
     - Creates MaintenanceJob records
     - Updates next_due_date based on pattern
   - Usage-based triggers:
     - Track equipment hours (if available)
     - Trigger maintenance every N hours of use

2. MAINT-102: Maintenance Calendar View (8 pts)
   - API endpoint: GET /api/v1/maintenance_calendar
   - Query params:
     - start_date, end_date (date range)
     - product_id (optional filter)
     - technician_id (optional filter)
     - status (scheduled, in_progress, completed)
   - Return format:
     ```json
     {
       "calendar_events": [
         {
           "id": 123,
           "title": "Camera Sensor Cleaning",
           "product_name": "Canon EOS R5",
           "scheduled_date": "2026-03-15",
           "estimated_duration": "2 hours",
           "technician": "John Doe",
           "status": "scheduled",
           "maintenance_type": "routine"
         }
       ]
     }
     ```
   - Group by week/month view
   - Conflict detection (technician double-booked)

3. MAINT-103: Maintenance Due Notifications (5 pts)
   - Create NotificationService class
   - Implement SendMaintenanceDueNotificationsJob:
     - Runs daily at 8am
     - Finds maintenance due in next 7 days
     - Sends email to assigned technician
     - Sends email to manager if overdue
   - Notification types:
     - 7 days before due: "Upcoming maintenance"
     - Due date: "Maintenance due today"
     - Overdue: "URGENT: Maintenance overdue"
   - Track notification history:
     - Add notified_at to maintenance_jobs
     - Prevent duplicate notifications

4. MAINT-104: Block Equipment When Maintenance Due (8 pts)
   - Add maintenance_status to products/product_instances:
     - current: no maintenance due
     - due_soon: due within 7 days (show warning)
     - overdue: past due date (block rentals)
     - in_maintenance: currently being serviced
   - Modify availability check:
     - Product.available_for_booking? checks maintenance_status
     - Return error: "Equipment requires maintenance before rental"
   - API changes:
     - GET /api/v1/products/:id/availability includes maintenance_status
     - Booking creation validates no overdue maintenance
   - Override mechanism:
     - Allow admin to override (with reason logged)
     - Track override in audit trail

5. MAINT-105: Maintenance History Tracking (5 pts)
   - Enhance MaintenanceJob with:
     - actual_duration_hours: decimal
     - findings: text (what was discovered)
     - actions_taken: text (what was done)
     - parts_used: jsonb (array of part_id, quantity)
     - total_cost_breakdown: jsonb (labor, parts, other)
     - before_photos: active_storage attachments
     - after_photos: active_storage attachments
   - API endpoints:
     - GET /api/v1/products/:id/maintenance_history
     - GET /api/v1/maintenance_jobs/:id/complete (mark complete)
     - POST /api/v1/maintenance_jobs/:id/photos (upload)
   - Generate maintenance report:
     - Equipment service history
     - Total maintenance cost
     - MTBF (Mean Time Between Failures)
     - Reliability score

TECHNICAL IMPLEMENTATION:

1. Models to Create/Update:
   - MaintenanceSchedule (new)
   - MaintenanceJob (enhance existing)
   - Product (add maintenance_status field)
   - ProductInstance (add maintenance_status field)

2. Services:
   - MaintenanceScheduler (calculate next due dates)
   - NotificationService (send maintenance alerts)

3. Background Jobs:
   - GenerateRecurringMaintenanceJob (daily cron)
   - SendMaintenanceDueNotificationsJob (daily cron)
   - UpdateMaintenanceStatusJob (hourly cron)

4. API Controllers:
   - MaintenanceSchedulesController (CRUD)
   - MaintenanceCalendarController (calendar view)
   - MaintenanceJobsController (enhance existing)

MIGRATIONS:
- create_maintenance_schedules
- add_maintenance_fields_to_maintenance_jobs (recurring fields)
- add_maintenance_status_to_products
- add_maintenance_status_to_product_instances
- add_maintenance_metrics_to_maintenance_jobs

DATABASE INDEXES:
- index maintenance_schedules on next_due_date
- index maintenance_jobs on scheduled_date
- index products on maintenance_status
- composite index on (product_id, next_due_date)

TESTING:
- Test recurrence pattern calculation (weekly, monthly, yearly)
- Test usage-based triggers
- Test equipment blocking when overdue
- Test notification sending
- Test calendar view with filters

SUCCESS CRITERIA:
- 90% compliance with maintenance schedules
- Zero rentals of equipment with overdue maintenance
- 100% of maintenance jobs scheduled automatically
- Average 2-day advance notice for technicians
- Equipment downtime reduced by 50%
```

**Estimated Duration**: 6 weeks (Sprint 17-18)
**Story Points**: 39
**Dependencies**: Cron jobs configured, email notifications working

---

## 📊 Feature #3: FIN - Financial Reporting & Analytics

### Epic: FIN (Sprint 18-19, 42 story points)

**Business Goal**: Provide CFO-level financial visibility, save $50K+ annually in accounting time

---

### Implementation Prompt

```
Use backend-developer skill to implement Financial Reporting & Analytics (FIN epic).

CONTEXT:
- All financial data exists: bookings, payments, line_items, costs
- We have AR aging reports already built
- Goal: Generate comprehensive financial reports for business decisions

REQUIREMENTS:

1. FIN-101: Profit & Loss Statement (13 pts)
   - Create FinancialReport model:
     - report_type: profit_loss, balance_sheet, cash_flow, revenue_breakdown
     - period_type: monthly, quarterly, annual, custom
     - start_date, end_date
     - data: jsonb (calculated report data)
     - generated_at, generated_by
   - P&L Calculation:
     ```ruby
     REVENUE:
     - Rental Revenue (from bookings.total_price)
     - Sale Revenue (sale items)
     - Service Revenue (service items)
     - Late Fees (from bookings)
     - Damage Fees (from damage_reports)
     - Delivery Fees (from deliveries)
     TOTAL REVENUE

     COST OF GOODS SOLD:
     - Equipment Depreciation (calculated)
     - Direct Labor (staff time on bookings)
     TOTAL COGS

     GROSS PROFIT = REVENUE - COGS

     OPERATING EXPENSES:
     - Maintenance Costs (from maintenance_jobs)
     - Delivery Costs (from deliveries)
     - Marketing Expenses
     - Salaries
     - Rent/Utilities
     - Insurance
     TOTAL OPERATING EXPENSES

     OPERATING INCOME = GROSS PROFIT - OPERATING EXPENSES

     OTHER INCOME/EXPENSES:
     - Interest Income
     - Interest Expense
     NET INCOME = OPERATING INCOME + OTHER
     ```
   - API: POST /api/v1/financial_reports/profit_loss
     ```json
     {
       "start_date": "2026-01-01",
       "end_date": "2026-01-31",
       "period_type": "monthly"
     }
     ```
   - Response time: < 3 seconds for monthly report

2. FIN-102: Revenue Breakdown by Category (8 pts)
   - Revenue analysis dimensions:
     - By Product Category (cameras, lenses, lighting, audio)
     - By Client (top 10 clients)
     - By Client Industry (events, film, corporate)
     - By Location (if multi-location)
     - By Time Period (daily, weekly, monthly trends)
   - Create RevenueAnalysis service:
     ```ruby
     class RevenueAnalysis
       def by_category(start_date, end_date)
       def by_client(start_date, end_date, limit: 10)
       def by_product(start_date, end_date, limit: 20)
       def by_month(year)
       def growth_trend(months: 12)
     end
     ```
   - API endpoints:
     - GET /api/v1/analytics/revenue/by_category
     - GET /api/v1/analytics/revenue/by_client
     - GET /api/v1/analytics/revenue/trends
   - Visualization data format:
     ```json
     {
       "categories": [
         {"name": "Cameras", "revenue": 125000, "percentage": 45.5},
         {"name": "Lenses", "revenue": 89000, "percentage": 32.4}
       ],
       "total_revenue": 275000
     }
     ```

3. FIN-103: Expense Tracking (8 pts)
   - Create Expense model:
     - category: maintenance, delivery, marketing, salaries, rent, utilities, insurance, supplies, other
     - amount_cents, amount_currency
     - date, vendor, invoice_number
     - description, notes
     - payment_method, payment_date
     - belongs_to :company (multi-tenant)
     - attachments (receipts via Active Storage)
   - Expense categories with budgets:
     - Create ExpenseBudget model:
       - category, period_type (monthly, quarterly, annual)
       - budgeted_amount_cents
       - track actual vs. budget variance
   - API endpoints:
     - POST /api/v1/expenses (create expense)
     - GET /api/v1/expenses (list with filters)
     - GET /api/v1/expenses/summary (by category)
   - Alerts:
     - Notify when category exceeds 80% of budget
     - Monthly expense recap email

4. FIN-104: Equipment ROI Calculation (5 pts)
   - Add ROI metrics to Product/ProductInstance:
     - purchase_price (already exists)
     - purchase_date (already exists)
     - accumulated_revenue (calculated)
     - accumulated_maintenance_cost (calculated)
     - days_owned (calculated)
     - days_rented (calculated)
     - utilization_rate (already exists)
   - ROI calculations:
     ```ruby
     # Net Profit = Revenue - (Maintenance + Depreciation)
     # ROI % = (Net Profit / Purchase Price) * 100
     # Payback Period = Purchase Price / Average Monthly Revenue
     # Revenue per Day Owned = Total Revenue / Days Owned
     ```
   - API endpoint:
     - GET /api/v1/products/:id/roi
     - GET /api/v1/analytics/equipment_roi (all products)
   - Identify underperforming assets:
     - ROI < 0% after 1 year (losing money)
     - Utilization < 20% (consider selling)
     - High maintenance cost (> 30% of revenue)

5. FIN-105: Financial Reports (Monthly/Quarterly/Annual) (8 pts)
   - Create ScheduledReport model:
     - report_type: profit_loss, revenue_summary, expense_summary
     - frequency: weekly, monthly, quarterly, annual
     - recipients: jsonb (array of email addresses)
     - format: pdf, csv, excel
     - next_send_date
   - Report generation:
     - Generate PDF using Prawn gem
     - Include charts (revenue trends, expense breakdown)
     - Professional formatting with company logo
   - Scheduled delivery:
     - GenerateScheduledReportsJob (daily cron)
     - Checks next_send_date
     - Generates report and emails
   - Report templates:
     - Monthly Management Report:
       - P&L summary
       - Revenue vs. target
       - Top 5 revenue products
       - Top 5 clients
       - Cash flow summary
     - Quarterly Board Report:
       - Executive summary
       - YTD P&L
       - Key metrics (revenue growth, margins)
       - Equipment ROI analysis
   - API:
     - POST /api/v1/scheduled_reports (create)
     - GET /api/v1/reports/download/:id (download PDF)

TECHNICAL IMPLEMENTATION:

1. Models:
   - FinancialReport (new)
   - Expense (new)
   - ExpenseBudget (new)
   - ScheduledReport (new)

2. Services:
   - FinancialCalculator (P&L, balance sheet calculations)
   - RevenueAnalysis (breakdown and trends)
   - RoiCalculator (equipment ROI)
   - ReportGenerator (PDF generation)

3. Background Jobs:
   - GenerateScheduledReportsJob (daily cron)
   - CacheFinancialMetricsJob (hourly - for dashboard)

4. API Controllers:
   - FinancialReportsController
   - ExpensesController
   - AnalyticsController (revenue, ROI)
   - ScheduledReportsController

MIGRATIONS:
- create_financial_reports
- create_expenses
- create_expense_budgets
- create_scheduled_reports
- add_financial_metrics_to_products

DEPENDENCIES:
- Prawn gem (PDF generation)
- Chartkick gem (charts in reports)
- Spreadsheet gem (Excel export)

CACHING STRATEGY:
- Cache monthly P&L for current month (invalidate on new transaction)
- Cache revenue breakdowns (refresh hourly)
- Cache ROI calculations (refresh daily)

TESTING:
- Test P&L calculation accuracy
- Test revenue breakdown grouping
- Test ROI formulas
- Test PDF generation
- Test scheduled report delivery
- Test budget variance alerts

SUCCESS CRITERIA:
- P&L generation < 3 seconds
- 100% accuracy (matches QuickBooks/Xero)
- CFOs can make decisions without manual spreadsheets
- Automated monthly reports delivered
- Equipment ROI visible for all assets
```

**Estimated Duration**: 6 weeks (Sprint 18-19)
**Story Points**: 42
**Dependencies**: Prawn gem for PDF generation, Chartkick for charts

---

## 📋 Execution Checklist

### Pre-Implementation (Week 0)

**For EMAIL Epic:**
- [ ] Sign up for SendGrid account (Free tier: 100 emails/day, or $15/mo for 40k emails)
- [ ] Get SendGrid API key
- [ ] Add `SENDGRID_API_KEY` to environment variables
- [ ] Install Sidekiq for background jobs (if not already)
- [ ] Install `sendgrid-ruby` gem

**For MAINT Epic:**
- [ ] Review existing `maintenance_jobs` table schema
- [ ] Set up cron job runner (whenever gem + config/schedule.rb)
- [ ] Identify 3-5 pilot products for testing recurring schedules

**For FIN Epic:**
- [ ] Install reporting gems: `prawn`, `chartkick`, `spreadsheet`
- [ ] Review existing financial data quality (bookings, payments)
- [ ] Define expense categories for your business
- [ ] Get sample P&L format from CFO/accountant

---

## 🎯 Quick Start Commands

### Start EMAIL Epic:
```bash
# Copy this prompt to Claude:
"Use backend-developer skill to implement EMAIL epic (Sprint 20-21, 31 pts).
Follow the detailed requirements in .claude/backlog/IMPLEMENTATION_PROMPTS.md
under Feature #1: EMAIL - Email Marketing Automation.
Start with EMAIL-101: Quote Follow-up Automation."
```

### Start MAINT Epic:
```bash
# Copy this prompt to Claude:
"Use backend-developer skill to implement MAINT epic (Sprint 17-18, 39 pts).
Follow the detailed requirements in .claude/backlog/IMPLEMENTATION_PROMPTS.md
under Feature #2: MAINT - Preventive Maintenance Scheduling.
Start with MAINT-101: Schedule Recurring Maintenance."
```

### Start FIN Epic:
```bash
# Copy this prompt to Claude:
"Use backend-developer skill to implement FIN epic (Sprint 18-19, 42 pts).
Follow the detailed requirements in .claude/backlog/IMPLEMENTATION_PROMPTS.md
under Feature #3: FIN - Financial Reporting & Analytics.
Start with FIN-101: Profit & Loss Statement."
```

---

## 📊 Progress Tracking

Use this template to track implementation:

```markdown
## EMAIL Epic Progress

- [ ] EMAIL-101: Quote Follow-up Automation (8 pts)
  - [ ] EmailCampaign model created
  - [ ] EmailSequence model created
  - [ ] Automatic triggers implemented
  - [ ] Tests passing

- [ ] EMAIL-102: Past Customer Re-engagement (5 pts)
- [ ] EMAIL-103: Email Template Builder (8 pts)
- [ ] EMAIL-104: Customer Segmentation (5 pts)
- [ ] EMAIL-105: Email Analytics Dashboard (5 pts)
- [ ] SendGrid integration complete
- [ ] Production deployment

**Sprint Velocity**: ___ points completed / 31 total
**Estimated Completion**: Sprint ___
```

---

## 🚨 Risk Mitigation

### EMAIL Risks:
- **Email deliverability**: Use SendGrid's domain authentication (SPF, DKIM)
- **Spam complaints**: Implement one-click unsubscribe, honor opt-outs immediately
- **Data privacy**: Add GDPR-compliant consent tracking

### MAINT Risks:
- **Over-aggressive blocking**: Implement admin override for urgent rentals
- **Technician capacity**: Schedule maintenance considering technician availability
- **Calculation errors**: Thoroughly test recurrence pattern edge cases (leap years, month-end dates)

### FIN Risks:
- **Calculation accuracy**: Validate against existing accounting software (QuickBooks)
- **Performance**: Cache expensive calculations, use database aggregations
- **Rounding errors**: Use Money gem consistently, always store cents as integers

---

**Next Steps**: Choose which epic to start based on business urgency, copy the appropriate prompt to Claude, and begin implementation!
