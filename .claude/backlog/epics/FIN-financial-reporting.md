# Epic: Financial Reporting & Analytics

**Epic ID**: FIN
**Status**: Backlog
**Priority**: CRITICAL
**Business Value**: HIGH
**Target Release**: Phase 1 - Q2 2026

---

## Overview

Comprehensive financial reporting system including P&L statements, expense tracking, revenue analytics, and financial forecasting. Essential for rental companies to understand profitability, manage cash flow, and make data-driven decisions.

## Business Problem

Rental companies currently lack visibility into:
- True profitability per product category, location, and customer segment
- Operating expenses broken down by type
- Cash flow projections
- Revenue trends and seasonality
- Equipment ROI and utilization rates

This leads to poor pricing decisions, overstocking unprofitable items, and missed growth opportunities.

## Success Metrics

- **Primary**: Complete P&L statement generated in <3 seconds
- **Secondary**:
  - 100% accuracy vs. manual accounting records
  - Finance team saves 20+ hours/month on manual reporting
  - Revenue forecasting within 10% accuracy
  - Identify 3+ cost-saving opportunities per quarter

## User Personas

1. **CFO/Finance Manager** - Strategic financial planning and investor reporting
2. **Owner/CEO** - Overall business health and decision making
3. **Accountant** - Detailed expense tracking and reconciliation
4. **Operations Manager** - Cost control and budget management

---

## User Stories

### Must Have (P0)
- [ ] FIN-101: Profit & Loss (P&L) statement generation (13 pts)
- [ ] FIN-102: Revenue breakdown by product category (8 pts)
- [ ] FIN-103: Expense tracking and categorization (8 pts)
- [ ] FIN-104: Equipment ROI calculation (5 pts)
- [ ] FIN-105: Monthly/quarterly/annual financial reports (8 pts)

### Should Have (P1)
- [ ] FIN-106: Cash flow projection (8 pts)
- [ ] FIN-107: Customer lifetime value (CLV) analysis (5 pts)
- [ ] FIN-108: Revenue by location/sales channel (5 pts)
- [ ] FIN-109: Budget vs. actual comparison (5 pts)
- [ ] FIN-110: Tax reporting (sales tax by jurisdiction) (8 pts)

### Nice to Have (P2)
- [ ] FIN-111: Financial dashboard with charts (13 pts)
- [ ] FIN-112: Export to QuickBooks/Xero (8 pts)
- [ ] FIN-113: Multi-currency support (8 pts)
- [ ] FIN-114: Financial forecasting (AI-powered) (13 pts)

**Total Story Points**: 115 pts (Must Have: 42 pts)

---

## Technical Architecture

### New Models
```ruby
class FinancialReport < ApplicationRecord
  belongs_to :company
  belongs_to :generated_by, class_name: 'User'

  enum report_type: [:profit_loss, :balance_sheet, :cash_flow, :expense_report]
  enum period: [:monthly, :quarterly, :yearly, :custom]

  validates :start_date, :end_date, presence: true
end

class ExpenseCategory < ApplicationRecord
  belongs_to :company

  # Categories: maintenance, insurance, storage, labor, marketing, etc.
  validates :name, presence: true, uniqueness: { scope: :company_id }
end

class Expense < ApplicationRecord
  belongs_to :company
  belongs_to :expense_category
  belongs_to :product, optional: true
  belongs_to :created_by, class_name: 'User'

  validates :amount_cents, :expense_date, presence: true
end

class RevenueBreakdown < ApplicationRecord
  belongs_to :company

  # Cached aggregations for performance
  # category, product, location, date_range, revenue_amount
end
```

### New Tables
- `financial_reports` - Generated report metadata
- `expenses` - Operating expenses
- `expense_categories` - Categorization for expenses
- `revenue_breakdowns` - Cached revenue aggregations
- `financial_metrics` - Cached KPIs (ROI, utilization, etc.)

### API Endpoints
```
# Reports
GET  /api/v1/financial_reports              # List reports
POST /api/v1/financial_reports              # Generate report
GET  /api/v1/financial_reports/:id          # View report
GET  /api/v1/financial_reports/profit_loss  # Quick P&L

# Expenses
GET    /api/v1/expenses                     # List expenses
POST   /api/v1/expenses                     # Create expense
PATCH  /api/v1/expenses/:id                 # Update expense
DELETE /api/v1/expenses/:id                 # Delete expense

# Analytics
GET /api/v1/analytics/revenue_by_category   # Revenue breakdown
GET /api/v1/analytics/equipment_roi         # ROI per product
GET /api/v1/analytics/expense_breakdown     # Expense analysis
GET /api/v1/analytics/cash_flow             # Cash flow projection
```

### Services
```ruby
class FinancialReportService
  # Generate comprehensive financial reports
  def generate_profit_loss(start_date, end_date)
  def generate_balance_sheet(as_of_date)
  def generate_cash_flow(start_date, end_date)
end

class RevenueAnalyticsService
  # Revenue analysis and breakdowns
  def revenue_by_category(date_range)
  def revenue_by_location(date_range)
  def revenue_trends(period)
end

class ExpenseAnalyticsService
  # Expense tracking and analysis
  def total_expenses_by_category(date_range)
  def expense_trends(period)
  def budget_variance(budget_plan)
end

class EquipmentROIService
  # Calculate return on investment per equipment
  def calculate_roi(product, period)
  def utilization_rate(product, period)
  def total_revenue_generated(product, period)
end
```

### Background Jobs
- `FinancialReportGeneratorJob` - Heavy report generation
- `RevenueCacheUpdateJob` - Update cached aggregations
- `MonthlyReportSchedulerJob` - Auto-generate monthly reports

---

## Database Design

### Key Calculations

**Profit & Loss Components:**
```ruby
# Revenue
total_revenue = Booking.completed.sum(:total_price_cents)

# Cost of Goods Sold (COGS)
cogs = (
  Expense.where(category: 'product_cost').sum(:amount_cents) +
  MaintenanceLog.sum(:cost_cents)
)

# Operating Expenses
operating_expenses = Expense.where(category: [
  'rent', 'utilities', 'insurance', 'salaries',
  'marketing', 'administrative'
]).sum(:amount_cents)

# Gross Profit
gross_profit = total_revenue - cogs

# Net Profit
net_profit = gross_profit - operating_expenses
```

**Equipment ROI:**
```ruby
def calculate_equipment_roi(product, period)
  revenue = product.bookings
    .where(start_date: period)
    .sum(:total_price_cents)

  costs = (
    product.purchase_price_cents +
    product.expenses.where(expense_date: period).sum(:amount_cents) +
    product.maintenance_logs.where(completed_at: period).sum(:cost_cents)
  )

  roi_percentage = ((revenue - costs).to_f / costs) * 100
end
```

---

## Dependencies

### Blocking
- Stripe integration (existing) - Payment data
- Booking system (existing) - Revenue data

### Integration Points
- Accounting software (QuickBooks, Xero) - Data export
- Tax calculation service - Tax reporting
- Banking APIs - Cash flow data

---

## Risks & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Complex financial calculations | Medium | High | Use established accounting formulas, CPA review |
| Performance with large datasets | High | High | Implement caching, background jobs |
| Data accuracy concerns | Medium | Critical | Extensive testing, reconciliation tools |
| Tax compliance complexity | High | High | Consult tax professional, scope to basics first |
| Multi-currency handling | Low | Medium | Phase 2 feature |

---

## Compliance & Security

- **Data Retention**: Financial records retained for 7 years per IRS requirements
- **Access Control**: Role-based access (only finance team can view)
- **Audit Trail**: All financial data changes logged
- **Data Encryption**: Sensitive financial data encrypted at rest

---

## Out of Scope

- Payroll processing (use third-party)
- Accounts receivable/payable aging (Phase 2)
- Automated bank reconciliation (Phase 2)
- Multi-entity consolidation (Phase 3)
- Advanced financial forecasting/modeling (Phase 3)

---

## Estimation

**Total Effort**: 18-25 days
- Backend: 12 days
- Frontend: 8 days
- Testing: 5 days
- DevOps: 2 days (caching, performance)

**Team Capacity**: 2 developers + 1 QA + 1 finance SME (consulting)
**Target Completion**: End of Sprint 19

---

## Success Criteria

- [ ] Generate complete P&L statement in <3 seconds
- [ ] 100% accuracy when compared to manual calculations
- [ ] Revenue breakdown by 10+ dimensions (category, product, location, etc.)
- [ ] Expense tracking with 20+ categories
- [ ] Equipment ROI calculated for all products
- [ ] Export to CSV/Excel/PDF
- [ ] 95% test coverage
- [ ] Performance tested with 10,000+ bookings

---

## Related Epics

- **STRIPE**: Payment processing and revenue data (dependency)
- **FORECAST**: Advanced forecasting (future integration)
- **MULTI-TENANCY**: Per-company financial isolation (implemented)
- **TAX**: Tax calculation and reporting (related)

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| 2026-02-28 | Product Owner | Epic created |
