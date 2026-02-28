# Service for calculating Profit & Loss statements and financial metrics
module Financial
  class FinancialCalculator
    attr_reader :company, :start_date, :end_date

    def initialize(company:, start_date:, end_date:)
      @company = company
      @start_date = start_date
      @end_date = end_date
    end

    # Generate complete P&L statement
    def calculate_profit_loss
      {
        period: {
          start_date: start_date,
          end_date: end_date,
          days: (end_date - start_date).to_i + 1
        },
        revenue: calculate_revenue,
        cost_of_goods_sold: calculate_cogs,
        gross_profit: calculate_gross_profit,
        operating_expenses: calculate_operating_expenses,
        operating_income: calculate_operating_income,
        other_income_expenses: calculate_other_income_expenses,
        net_income: calculate_net_income,
        metrics: calculate_metrics
      }
    end

    private

    def calculate_revenue
      rental_revenue = calculate_rental_revenue
      sale_revenue = calculate_sale_revenue
      service_revenue = calculate_service_revenue
      late_fees = calculate_late_fees
      damage_fees = calculate_damage_fees
      delivery_fees = calculate_delivery_fees

      total = rental_revenue + sale_revenue + service_revenue +
              late_fees + damage_fees + delivery_fees

      {
        rental: rental_revenue,
        sales: sale_revenue,
        services: service_revenue,
        late_fees: late_fees,
        damage_fees: damage_fees,
        delivery_fees: delivery_fees,
        total: total
      }
    end

    def calculate_rental_revenue
      # Sum of all rental bookings (excluding sales and services)
      line_items = BookingLineItem.joins(:booking)
                                   .where(bookings: { company_id: company.id })
                                   .where('bookings.start_date >= ? AND bookings.start_date <= ?', start_date, end_date)
                                   .where(bookable_type: ['Product', 'Kit'])

      # Calculate total by summing line_total method results
      line_items.to_a.sum { |item| item.line_total.cents }
    end

    def calculate_sale_revenue
      # Sum of all sale items
      line_items = BookingLineItem.joins(:booking)
                                   .where(bookings: { company_id: company.id })
                                   .where('bookings.start_date >= ? AND bookings.start_date <= ?', start_date, end_date)
                                   .where(bookable_type: 'Product')
                                   .joins("INNER JOIN products ON products.id = booking_line_items.bookable_id")
                                   .where("products.item_type = ?", Product.item_types[:sale_item]) rescue []

      # Calculate total by summing line_total method results
      line_items.to_a.sum { |item| item.line_total.cents }
    end

    def calculate_service_revenue
      # Sum of all service items
      line_items = BookingLineItem.joins(:booking)
                                   .where(bookings: { company_id: company.id })
                                   .where('bookings.start_date >= ? AND bookings.start_date <= ?', start_date, end_date)
                                   .where(bookable_type: 'Product')
                                   .joins("INNER JOIN products ON products.id = booking_line_items.bookable_id")
                                   .where("products.item_type = ?", Product.item_types[:service_item]) rescue []

      # Calculate total by summing line_total method results
      line_items.to_a.sum { |item| item.line_total.cents }
    end

    def calculate_late_fees
      # Sum of late fees from overdue returns
      BookingLineItem.joins(:booking)
                     .where(bookings: { company_id: company.id })
                     .where('booking_line_items.actual_return_date >= ? AND booking_line_items.actual_return_date <= ?', start_date, end_date)
                     .where('booking_line_items.late_fee_cents > 0')
                     .sum(:late_fee_cents)
    end

    def calculate_damage_fees
      # Sum of damage fees from damage reports
      return 0 unless defined?(DamageReport)

      begin
        DamageReport.where(company_id: company.id)
                    .where('reported_at >= ? AND reported_at <= ?', start_date, end_date)
                    .where.not(repair_cost_cents: nil)
                    .sum(:repair_cost_cents)
      rescue ActiveRecord::StatementInvalid
        # Table might not have the expected schema
        0
      end
    end

    def calculate_delivery_fees
      # Sum of delivery fees charged to customers
      BookingLineItem.joins(:booking)
                     .where(bookings: { company_id: company.id })
                     .where('bookings.start_date >= ? AND bookings.start_date <= ?', start_date, end_date)
                     .where.not(delivery_cost_cents: nil)
                     .sum(:delivery_cost_cents)
    end

    def calculate_cogs
      equipment_depreciation = calculate_equipment_depreciation
      direct_labor = calculate_direct_labor

      total = equipment_depreciation + direct_labor

      {
        equipment_depreciation: equipment_depreciation,
        direct_labor: direct_labor,
        total: total
      }
    end

    def calculate_equipment_depreciation
      # Calculate depreciation for all products used during the period
      Product.where(company: company)
             .where.not(purchase_price_cents: nil)
             .sum do |product|
               product.depreciation_for_period(start_date, end_date)
             end
    end

    def calculate_direct_labor
      # TODO: Implement staff time tracking
      # For now, return 0 as this requires time tracking system
      0
    end

    def calculate_gross_profit
      revenue = calculate_revenue[:total]
      cogs = calculate_cogs[:total]
      revenue - cogs
    end

    def calculate_operating_expenses
      maintenance = calculate_maintenance_costs
      delivery = calculate_delivery_costs
      tracked_expenses = calculate_tracked_expenses

      total = maintenance + delivery + tracked_expenses.values.sum

      {
        maintenance: maintenance,
        delivery: delivery,
        marketing: tracked_expenses[:marketing] || 0,
        salaries: tracked_expenses[:salaries] || 0,
        rent: tracked_expenses[:rent] || 0,
        utilities: tracked_expenses[:utilities] || 0,
        insurance: tracked_expenses[:insurance] || 0,
        supplies: tracked_expenses[:supplies] || 0,
        equipment_purchase: tracked_expenses[:equipment_purchase] || 0,
        software: tracked_expenses[:software] || 0,
        professional_services: tracked_expenses[:professional_services] || 0,
        travel: tracked_expenses[:travel] || 0,
        other: tracked_expenses[:other] || 0,
        total: total
      }
    end

    def calculate_maintenance_costs
      if defined?(MaintenanceJob)
        MaintenanceJob.where(company: company)
                      .where('completed_at >= ? AND completed_at <= ?', start_date, end_date)
                      .where(status: :completed)
                      .sum(:total_cost_cents)
      else
        # Fallback to expense tracking
        Expense.where(company: company)
               .where(category: :maintenance)
               .for_period(start_date, end_date)
               .sum(:amount_cents)
      end
    end

    def calculate_delivery_costs
      # Internal delivery costs (not charged to customers)
      Expense.where(company: company)
             .where(category: :delivery)
             .for_period(start_date, end_date)
             .sum(:amount_cents)
    end

    def calculate_tracked_expenses
      Expense.where(company: company)
             .for_period(start_date, end_date)
             .group(:category)
             .sum(:amount_cents)
    end

    def calculate_operating_income
      calculate_gross_profit - calculate_operating_expenses[:total]
    end

    def calculate_other_income_expenses
      # TODO: Implement interest income/expense tracking
      # For now, return zero
      {
        interest_income: 0,
        interest_expense: 0,
        other_income: 0,
        other_expense: 0,
        total: 0
      }
    end

    def calculate_net_income
      calculate_operating_income + calculate_other_income_expenses[:total]
    end

    def calculate_metrics
      revenue = calculate_revenue[:total]
      gross_profit = calculate_gross_profit
      net_income = calculate_net_income

      {
        gross_margin_percentage: revenue.zero? ? 0 : (gross_profit.to_f / revenue * 100).round(2),
        net_margin_percentage: revenue.zero? ? 0 : (net_income.to_f / revenue * 100).round(2),
        operating_ratio: revenue.zero? ? 0 : (calculate_operating_expenses[:total].to_f / revenue * 100).round(2)
      }
    end
  end
end
