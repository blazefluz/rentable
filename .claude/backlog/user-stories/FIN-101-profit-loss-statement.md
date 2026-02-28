# User Story: Generate Profit & Loss Statement

**Story ID**: FIN-101
**Epic**: [FIN - Financial Reporting](../epics/FIN-financial-reporting.md)
**Status**: Ready
**Priority**: CRITICAL (P0)
**Points**: 13
**Sprint**: Sprint 18
**Assigned To**: backend-developer

---

## Story

**As a** CFO/Finance Manager
**I want to** generate comprehensive P&L statements for any time period
**So that** I can understand business profitability and make informed financial decisions

---

## Acceptance Criteria

- [ ] **Given** I select a date range (start_date, end_date)
      **When** I request a P&L report
      **Then** I receive a complete profit & loss statement with revenue, COGS, expenses, and net profit

- [ ] **Given** I generate a P&L report
      **When** I view the results
      **Then** I see revenue broken down by product categories

- [ ] **Given** I generate a P&L report
      **When** I view operating expenses
      **Then** I see expenses categorized (maintenance, insurance, marketing, administrative, etc.)

- [ ] **Given** A large company with 10,000+ bookings
      **When** Generating annual P&L
      **Then** Report completes in <3 seconds

- [ ] **Given** I generate a P&L report
      **When** Report is complete
      **Then** I can export to PDF, CSV, and Excel formats

---

## Technical Details

### Database Schema
```sql
-- Financial reports table
CREATE TABLE financial_reports (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id),
  generated_by_id BIGINT NOT NULL REFERENCES users(id),

  report_type VARCHAR(50) NOT NULL CHECK (report_type IN ('profit_loss', 'balance_sheet', 'cash_flow')),
  period VARCHAR(50) NOT NULL CHECK (period IN ('monthly', 'quarterly', 'yearly', 'custom')),

  start_date DATE NOT NULL,
  end_date DATE NOT NULL,

  -- Cached calculations (JSON)
  report_data JSONB,

  generated_at TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW()
);

-- Expenses table
CREATE TABLE expenses (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id),
  expense_category_id BIGINT REFERENCES expense_categories(id),
  product_id BIGINT REFERENCES products(id),
  created_by_id BIGINT NOT NULL REFERENCES users(id),

  amount_cents BIGINT NOT NULL,
  currency VARCHAR(3) DEFAULT 'USD',

  expense_date DATE NOT NULL,
  description TEXT,
  receipt_url VARCHAR(500),

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_expenses_company_date ON expenses(company_id, expense_date);
CREATE INDEX idx_expenses_category ON expenses(expense_category_id);

-- Expense categories
CREATE TABLE expense_categories (
  id BIGSERIAL PRIMARY KEY,
  company_id BIGINT NOT NULL REFERENCES companies(id),

  name VARCHAR(100) NOT NULL,
  category_type VARCHAR(50) NOT NULL CHECK (category_type IN ('cogs', 'operating', 'administrative')),

  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),

  UNIQUE(company_id, name)
);
```

### API Endpoints
- `POST /api/v1/financial_reports/generate` - Generate new report
- `GET /api/v1/financial_reports/:id` - View report
- `GET /api/v1/financial_reports/:id/export?format=pdf` - Export report

### Service
```ruby
class FinancialReportService
  def generate_profit_loss(company, start_date, end_date)
    # Revenue
    total_revenue = calculate_revenue(company, start_date, end_date)
    revenue_by_category = revenue_breakdown_by_category(company, start_date, end_date)

    # Cost of Goods Sold
    cogs = calculate_cogs(company, start_date, end_date)

    # Gross Profit
    gross_profit = total_revenue - cogs
    gross_margin_percent = (gross_profit.to_f / total_revenue * 100).round(2)

    # Operating Expenses
    operating_expenses = calculate_operating_expenses(company, start_date, end_date)
    expenses_by_category = expenses_breakdown(company, start_date, end_date)

    # Net Profit
    net_profit = gross_profit - operating_expenses
    net_margin_percent = (net_profit.to_f / total_revenue * 100).round(2)

    {
      period: "#{start_date} to #{end_date}",
      revenue: {
        total_cents: total_revenue,
        by_category: revenue_by_category
      },
      cogs: {
        total_cents: cogs
      },
      gross_profit: {
        amount_cents: gross_profit,
        margin_percent: gross_margin_percent
      },
      operating_expenses: {
        total_cents: operating_expenses,
        by_category: expenses_by_category
      },
      net_profit: {
        amount_cents: net_profit,
        margin_percent: net_margin_percent
      }
    }
  end

  private

  def calculate_revenue(company, start_date, end_date)
    company.bookings
      .where(status: :completed)
      .where('start_date >= ? AND start_date <= ?', start_date, end_date)
      .sum(:total_price_cents)
  end

  def calculate_cogs(company, start_date, end_date)
    company.expenses
      .joins(:expense_category)
      .where(expense_categories: { category_type: 'cogs' })
      .where('expense_date >= ? AND expense_date <= ?', start_date, end_date)
      .sum(:amount_cents)
  end
end
```

---

## Tasks

### Backend Tasks (Backend Developer)
- [ ] Create migrations for financial_reports, expenses, expense_categories tables (2h)
- [ ] Create Expense and ExpenseCategory models (2h)
- [ ] Create FinancialReportService with P&L logic (6h)
- [ ] Create API endpoints (3h)
- [ ] Implement PDF export (Prawn gem) (3h)
- [ ] Write unit and integration tests (3h)

### Testing Tasks (QA Tester)
- [ ] Test P&L calculations accuracy (3h)
- [ ] Test with large datasets (performance) (1h)
- [ ] Test export formats (1h)

**Total**: 24 hours (~13 points)

---

## Dependencies

- **Depends on**: Booking model (exists), Stripe payments (exists)
- **Blocks**: FIN-102 (revenue breakdown uses this foundation)

---

## Definition of Done

- [ ] All acceptance criteria met
- [ ] P&L generates in <3 seconds
- [ ] 100% calculation accuracy vs manual check
- [ ] PDF export working
- [ ] >90% test coverage

---

## Changelog

| Date | Author | Change |
|------|--------|--------|
| 2026-02-28 | Product Owner | Story created |
