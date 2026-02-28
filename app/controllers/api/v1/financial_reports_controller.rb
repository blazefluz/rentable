# API controller for generating financial reports
class Api::V1::FinancialReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_current_tenant
  before_action :set_date_range, only: [:profit_loss, :revenue_breakdown, :expense_summary]
  before_action :validate_dates, only: [:profit_loss, :revenue_breakdown, :expense_summary]

  # POST /api/v1/financial_reports/profit_loss
  # Generate Profit & Loss statement
  def profit_loss
    calculator = Financial::FinancialCalculator.new(
      company: ActsAsTenant.current_tenant,
      start_date: @start_date,
      end_date: @end_date
    )

    pl_data = calculator.calculate_profit_loss

    # Save the report
    report = FinancialReport.create!(
      company: ActsAsTenant.current_tenant,
      report_type: :profit_loss,
      period_type: determine_period_type,
      start_date: @start_date,
      end_date: @end_date,
      data: pl_data,
      generated_by: current_user
    )

    render json: {
      report: {
        id: report.id,
        report_type: report.report_type,
        period: report.period_description,
        generated_at: report.generated_at,
        data: format_pl_data(pl_data)
      }
    }, status: :created
  end

  # GET /api/v1/financial_reports/revenue_breakdown
  # Get revenue breakdown by various dimensions
  def revenue_breakdown
    dimension = params[:dimension] || 'category' # category, client, product, month, industry, location

    analyzer = Financial::RevenueAnalysis.new(company: ActsAsTenant.current_tenant)

    data = case dimension
    when 'category'
      analyzer.by_category(@start_date, @end_date)
    when 'client'
      analyzer.by_client(@start_date, @end_date, limit: params[:limit] || 10)
    when 'product'
      analyzer.by_product(@start_date, @end_date, limit: params[:limit] || 20)
    when 'industry'
      analyzer.by_industry(@start_date, @end_date)
    when 'location'
      analyzer.by_location(@start_date, @end_date)
    when 'month'
      year = params[:year]&.to_i || @start_date.year
      analyzer.by_month(year)
    when 'trend'
      months = params[:months]&.to_i || 12
      analyzer.growth_trend(months: months)
    else
      return render json: { error: 'Invalid dimension' }, status: :unprocessable_entity
    end

    # Save the report
    report = FinancialReport.create!(
      company: ActsAsTenant.current_tenant,
      report_type: :revenue_breakdown,
      period_type: determine_period_type,
      start_date: @start_date,
      end_date: @end_date,
      data: data.merge(dimension: dimension),
      generated_by: current_user
    )

    render json: {
      report: {
        id: report.id,
        dimension: dimension,
        period: report.period_description,
        generated_at: report.generated_at,
        data: data
      }
    }
  end

  # GET /api/v1/financial_reports/expense_summary
  # Get expense summary by category
  def expense_summary
    summary = Expense.by_category_summary(@start_date, @end_date)
    total_expenses = Expense.total_for_period(@start_date, @end_date)

    data = {
      period: { start_date: @start_date, end_date: @end_date },
      categories: summary.map do |category, amount|
        {
          category: category,
          amount: amount.cents,
          amount_formatted: amount.format,
          percentage: total_expenses.zero? ? 0 : (amount.cents.to_f / total_expenses * 100).round(2)
        }
      end.sort_by { |c| -c[:amount] },
      total_expenses: total_expenses,
      total_expenses_formatted: Money.new(total_expenses, 'USD').format
    }

    # Save the report
    report = FinancialReport.create!(
      company: ActsAsTenant.current_tenant,
      report_type: :expense_summary,
      period_type: determine_period_type,
      start_date: @start_date,
      end_date: @end_date,
      data: data,
      generated_by: current_user
    )

    render json: {
      report: {
        id: report.id,
        period: report.period_description,
        generated_at: report.generated_at,
        data: data
      }
    }
  end

  # GET /api/v1/financial_reports/roi_analysis
  # Get ROI analysis for all equipment or specific product
  def roi_analysis
    if params[:product_id].present?
      product = Product.find(params[:product_id])
      calculator = Financial::RoiCalculator.new(product: product)
      roi_data = calculator.calculate

      render json: { product_roi: roi_data }
    else
      # All products
      products = Product.where.not(purchase_price_cents: nil)
                        .where.not(purchase_date: nil)

      roi_results = products.map do |product|
        calculator = Financial::RoiCalculator.new(product: product)
        calculator.calculate
      end

      # Sort by ROI percentage (descending)
      roi_results.sort_by! { |r| -r.dig(:roi_metrics, :roi_percentage) }

      # Save the report
      report = FinancialReport.create!(
        company: ActsAsTenant.current_tenant,
        report_type: :roi_analysis,
        period_type: :custom,
        start_date: Date.current.beginning_of_year,
        end_date: Date.current,
        data: { products: roi_results },
        generated_by: current_user
      )

      render json: {
        report: {
          id: report.id,
          generated_at: report.generated_at,
          total_products: roi_results.count,
          data: {
            products: roi_results,
            summary: {
              total_investment: roi_results.sum { |r| r.dig(:purchase_info, :purchase_price) },
              total_revenue: roi_results.sum { |r| r.dig(:revenue_metrics, :total_revenue) },
              profitable_count: roi_results.count { |r| r.dig(:performance_indicators, :is_profitable) },
              underperforming_count: roi_results.count { |r| r.dig(:performance_indicators, :is_underperforming) }
            }
          }
        }
      }
    end
  end

  private

  def set_date_range
    @start_date = params[:start_date]&.to_date || Date.current.beginning_of_month
    @end_date = params[:end_date]&.to_date || Date.current.end_of_month
  end

  def validate_dates
    if @end_date < @start_date
      render json: { error: 'End date must be after start date' }, status: :unprocessable_entity
    end
  end

  def determine_period_type
    days = (@end_date - @start_date).to_i + 1

    case days
    when 1
      :daily
    when 7
      :weekly
    when 28..31
      :monthly
    when 89..92
      :quarterly
    when 365..366
      :annual
    else
      :custom
    end
  end

  def format_pl_data(data)
    {
      period: data[:period],
      revenue: format_money_section(data[:revenue]),
      cost_of_goods_sold: format_money_section(data[:cost_of_goods_sold]),
      gross_profit: data[:gross_profit],
      gross_profit_formatted: Money.new(data[:gross_profit], 'USD').format,
      operating_expenses: format_money_section(data[:operating_expenses]),
      operating_income: data[:operating_income],
      operating_income_formatted: Money.new(data[:operating_income], 'USD').format,
      other_income_expenses: format_money_section(data[:other_income_expenses]),
      net_income: data[:net_income],
      net_income_formatted: Money.new(data[:net_income], 'USD').format,
      metrics: data[:metrics]
    }
  end

  def format_money_section(section)
    section.transform_values do |value|
      if value.is_a?(Integer)
        {
          cents: value,
          formatted: Money.new(value, 'USD').format
        }
      else
        value
      end
    end
  end
end
