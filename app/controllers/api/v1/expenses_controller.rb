# API controller for expense tracking and management
class Api::V1::ExpensesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_current_tenant
  before_action :set_expense, only: [:show, :update, :destroy]

  # GET /api/v1/expenses
  def index
    @expenses = Expense.all
                       .includes(receipts_attachments: :blob)
                       .recent

    # Filter by category
    @expenses = @expenses.by_category(params[:category]) if params[:category].present?

    # Filter by date range
    if params[:start_date].present? && params[:end_date].present?
      @expenses = @expenses.for_period(params[:start_date].to_date, params[:end_date].to_date)
    end

    # Filter by payment status
    case params[:payment_status]
    when 'paid'
      @expenses = @expenses.paid
    when 'unpaid'
      @expenses = @expenses.unpaid
    end

    # Pagination
    page = params[:page] || 1
    per_page = params[:per_page] || 25
    @expenses = @expenses.page(page).per(per_page)

    render json: {
      expenses: @expenses.map { |expense| expense_json(expense) },
      meta: {
        current_page: @expenses.current_page,
        total_pages: @expenses.total_pages,
        total_count: @expenses.total_count,
        per_page: per_page.to_i
      }
    }
  end

  # GET /api/v1/expenses/:id
  def show
    render json: { expense: expense_json(@expense, include_receipts: true) }
  end

  # POST /api/v1/expenses
  def create
    @expense = Expense.new(expense_params)
    @expense.company = ActsAsTenant.current_tenant

    if @expense.save
      # Attach receipts if provided
      if params[:receipts].present?
        params[:receipts].each do |receipt|
          @expense.receipts.attach(receipt)
        end
      end

      # Check budget and send alert if needed
      check_budget_alert(@expense)

      render json: { expense: expense_json(@expense) }, status: :created
    else
      render json: { errors: @expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/expenses/:id
  def update
    if @expense.update(expense_params)
      # Update receipts if provided
      if params[:receipts].present?
        @expense.receipts.purge if params[:replace_receipts] == 'true'
        params[:receipts].each do |receipt|
          @expense.receipts.attach(receipt)
        end
      end

      render json: { expense: expense_json(@expense) }
    else
      render json: { errors: @expense.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/expenses/:id
  def destroy
    @expense.destroy
    head :no_content
  end

  # GET /api/v1/expenses/summary
  # Get expense summary by category for a period
  def summary
    start_date = params[:start_date]&.to_date || Date.current.beginning_of_month
    end_date = params[:end_date]&.to_date || Date.current.end_of_month

    summary_by_category = Expense.by_category_summary(start_date, end_date)
    total_expenses = Expense.total_for_period(start_date, end_date)

    # Get budget comparison
    budgets = ExpenseBudget.active
                           .where('start_date <= ? AND end_date >= ?', end_date, start_date)

    budget_comparison = budgets.map do |budget|
      actual_spent = summary_by_category[budget.category.to_sym] || Money.new(0, 'USD')
      {
        category: budget.category,
        budgeted: budget.budgeted_amount.cents,
        budgeted_formatted: budget.budgeted_amount.format,
        actual: actual_spent.cents,
        actual_formatted: actual_spent.format,
        variance: budget.variance.cents,
        variance_formatted: budget.variance.format,
        variance_percentage: budget.variance_percentage,
        over_budget: budget.over_budget?,
        approaching_limit: budget.approaching_limit?
      }
    end

    categories = summary_by_category.map do |category, amount|
      {
        category: category,
        amount: amount.cents,
        amount_formatted: amount.format,
        percentage: total_expenses.zero? ? 0 : (amount.cents.to_f / total_expenses * 100).round(2)
      }
    end.sort_by { |c| -c[:amount] }

    render json: {
      summary: {
        period: {
          start_date: start_date,
          end_date: end_date,
          days: (end_date - start_date).to_i + 1
        },
        categories: categories,
        budget_comparison: budget_comparison,
        total_expenses: total_expenses,
        total_expenses_formatted: Money.new(total_expenses, 'USD').format,
        total_budgeted: budgets.sum(:budgeted_amount_cents),
        total_budgeted_formatted: Money.new(budgets.sum(:budgeted_amount_cents), 'USD').format
      }
    }
  end

  private

  def set_expense
    @expense = Expense.find(params[:id])
  end

  def expense_params
    params.require(:expense).permit(
      :category,
      :amount_cents,
      :amount_currency,
      :date,
      :vendor,
      :invoice_number,
      :description,
      :notes,
      :payment_method,
      :payment_date
    )
  end

  def expense_json(expense, include_receipts: false)
    json = {
      id: expense.id,
      category: expense.category,
      amount: {
        cents: expense.amount_cents,
        formatted: expense.amount.format
      },
      date: expense.date,
      vendor: expense.vendor,
      invoice_number: expense.invoice_number,
      description: expense.description,
      notes: expense.notes,
      payment_method: expense.payment_method,
      payment_date: expense.payment_date,
      paid: expense.paid?,
      overdue: expense.overdue?,
      age_in_days: expense.age_in_days,
      created_at: expense.created_at,
      updated_at: expense.updated_at
    }

    if include_receipts && expense.receipts.attached?
      json[:receipts] = expense.receipts.map do |receipt|
        {
          id: receipt.id,
          filename: receipt.filename.to_s,
          content_type: receipt.content_type,
          byte_size: receipt.byte_size,
          url: rails_blob_url(receipt)
        }
      end
    else
      json[:receipts_count] = expense.receipts.count
    end

    json
  end

  def check_budget_alert(expense)
    # Find active budget for this category
    budget = ExpenseBudget.active
                          .by_category(expense.category)
                          .where('start_date <= ? AND end_date >= ?', expense.date, expense.date)
                          .first

    return unless budget

    # Check if approaching limit (80%) or over budget
    if budget.over_budget?
      # TODO: Send notification to admins about over-budget expense
      Rails.logger.warn "Expense category #{expense.category} is over budget!"
    elsif budget.approaching_limit?
      # TODO: Send notification about approaching budget limit
      Rails.logger.info "Expense category #{expense.category} is at #{budget.percentage_used}% of budget"
    end
  end
end
