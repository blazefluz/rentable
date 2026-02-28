# Database Query & Reporting

Generate comprehensive reports, analytics, and insights from the Rentable database.

## Description

This skill provides powerful database querying and reporting capabilities:
- Revenue and financial reporting
- Utilization and performance analytics
- Customer and booking insights
- Inventory status reports
- Aging and accounts receivable reports
- Custom SQL queries
- Data export and visualization

## When to Use

Use this skill when you need to:
- Generate revenue reports
- Analyze equipment utilization
- Track customer booking patterns
- Review inventory status
- Monitor overdue items
- Create accounts receivable aging reports
- Export data for external analysis
- Debug data inconsistencies

## Financial Reports

### Revenue Report by Period
```ruby
ActsAsTenant.with_tenant(company) do
  start_date = 1.month.ago
  end_date = Date.today

  puts "REVENUE REPORT"
  puts "Period: #{start_date.strftime('%Y-%m-%d')} to #{end_date.strftime('%Y-%m-%d')}"
  puts "=" * 80
  puts ""

  # Total revenue
  bookings = Booking.where(
    "created_at >= ? AND created_at <= ?",
    start_date,
    end_date
  ).where(status: [:paid, :completed])

  total_revenue = bookings.sum(:grand_total_cents)
  subtotal = bookings.sum(:subtotal_cents)
  tax_total = bookings.sum(:tax_total_cents)

  puts "Summary:"
  puts "  Total Bookings: #{bookings.count}"
  puts "  Subtotal: $#{subtotal / 100.0}"
  puts "  Tax Collected: $#{tax_total / 100.0}"
  puts "  Total Revenue: $#{total_revenue / 100.0}"
  puts ""

  # Revenue by status
  puts "Revenue by Status:"
  Booking.where(
    "created_at >= ? AND created_at <= ?",
    start_date,
    end_date
  ).group(:status).sum(:grand_total_cents).each do |status, amount|
    puts "  #{status.to_s.titleize}: $#{amount / 100.0}"
  end
  puts ""

  # Revenue by product category
  puts "Revenue by Category:"
  categories = BookingLineItem.joins(:booking, :bookable)
    .where("bookings.created_at >= ? AND bookings.created_at <= ?", start_date, end_date)
    .where(bookable_type: "Product")
    .where("bookings.status IN (?)", [:paid, :completed])
    .joins("INNER JOIN products ON products.id = booking_line_items.bookable_id")
    .group("products.category")
    .sum("booking_line_items.line_total_cents")

  categories.each do |category, amount|
    puts "  #{category}: $#{amount / 100.0}"
  end
  puts ""

  # Top revenue products
  puts "Top 10 Revenue Products:"
  top_products = BookingLineItem.joins(:booking, :bookable)
    .where("bookings.created_at >= ? AND bookings.created_at <= ?", start_date, end_date)
    .where(bookable_type: "Product")
    .where("bookings.status IN (?)", [:paid, :completed])
    .group(:bookable_id)
    .sum(:line_total_cents)
    .sort_by { |_, amount| -amount }
    .first(10)

  top_products.each_with_index do |(product_id, amount), index|
    product = Product.find(product_id)
    puts "  #{index + 1}. #{product.name}: $#{amount / 100.0}"
  end
end
```

### Monthly Revenue Comparison
```ruby
ActsAsTenant.with_tenant(company) do
  puts "MONTHLY REVENUE COMPARISON (Last 12 Months)"
  puts "=" * 80
  puts ""

  (0..11).reverse_each do |months_ago|
    month_start = months_ago.months.ago.beginning_of_month
    month_end = months_ago.months.ago.end_of_month

    revenue = Booking.where(
      "created_at >= ? AND created_at <= ?",
      month_start,
      month_end
    ).where(status: [:paid, :completed])
     .sum(:grand_total_cents)

    booking_count = Booking.where(
      "created_at >= ? AND created_at <= ?",
      month_start,
      month_end
    ).where(status: [:paid, :completed]).count

    avg_booking = booking_count > 0 ? revenue / booking_count : 0

    puts "#{month_start.strftime('%B %Y')}:"
    puts "  Revenue: $#{revenue / 100.0}"
    puts "  Bookings: #{booking_count}"
    puts "  Avg Booking Value: $#{avg_booking / 100.0}"
    puts ""
  end
end
```

## Utilization Reports

### Equipment Utilization Analysis
```ruby
ActsAsTenant.with_tenant(company) do
  start_date = 3.months.ago
  end_date = Date.today

  puts "EQUIPMENT UTILIZATION REPORT"
  puts "Period: #{start_date.strftime('%Y-%m-%d')} to #{end_date.strftime('%Y-%m-%d')}"
  puts "=" * 80
  puts ""

  Product.where(active: true).each do |product|
    # Calculate days rented
    days_rented = BookingLineItem.joins(:booking)
      .where(bookable: product)
      .where("bookings.start_date >= ? AND bookings.end_date <= ?", start_date, end_date)
      .where("bookings.status IN (?)", [:paid, :in_progress, :completed])
      .sum("booking_line_items.days * booking_line_items.quantity")

    # Calculate total possible days
    total_days = (end_date - start_date).to_i + 1
    total_possible_days = total_days * product.quantity

    # Utilization percentage
    utilization = total_possible_days > 0 ? (days_rented.to_f / total_possible_days * 100).round(2) : 0

    # Revenue generated
    revenue = BookingLineItem.joins(:booking)
      .where(bookable: product)
      .where("bookings.start_date >= ? AND bookings.end_date <= ?", start_date, end_date)
      .where("bookings.status IN (?)", [:paid, :completed])
      .sum(:line_total_cents)

    # Revenue per day
    revenue_per_day = days_rented > 0 ? revenue / days_rented : 0

    puts "#{product.name} (#{product.category}):"
    puts "  Quantity: #{product.quantity}"
    puts "  Days Rented: #{days_rented} / #{total_possible_days}"
    puts "  Utilization: #{utilization}%"
    puts "  Revenue: $#{revenue / 100.0}"
    puts "  Revenue/Day: $#{revenue_per_day / 100.0}"
    puts ""
  end

  # Summary statistics
  total_utilization = Product.where(active: true).average("
    (SELECT COALESCE(SUM(bli.days * bli.quantity), 0)
     FROM booking_line_items bli
     INNER JOIN bookings b ON b.id = bli.booking_id
     WHERE bli.bookable_id = products.id
       AND bli.bookable_type = 'Product'
       AND b.start_date >= '#{start_date}'
       AND b.end_date <= '#{end_date}'
       AND b.status IN ('paid', 'in_progress', 'completed'))
    /
    (#{(end_date - start_date).to_i + 1} * products.quantity * 1.0) * 100
  ")

  puts "Overall Average Utilization: #{total_utilization.to_f.round(2)}%"
end
```

### Low Utilization Alert
```ruby
ActsAsTenant.with_tenant(company) do
  threshold = 20  # 20% utilization threshold
  period = 90.days

  puts "LOW UTILIZATION ALERT (<#{threshold}%)"
  puts "Period: Last #{period / 1.day} days"
  puts "=" * 80
  puts ""

  Product.where(active: true).each do |product|
    days_rented = BookingLineItem.joins(:booking)
      .where(bookable: product)
      .where("bookings.start_date >= ?", period.ago)
      .where("bookings.status IN (?)", [:paid, :in_progress, :completed])
      .sum("booking_line_items.days * booking_line_items.quantity")

    total_possible = period / 1.day * product.quantity
    utilization = (days_rented.to_f / total_possible * 100).round(2)

    if utilization < threshold
      puts "⚠️  #{product.name}:"
      puts "   Utilization: #{utilization}%"
      puts "   Days Rented: #{days_rented} / #{total_possible}"
      puts "   Daily Price: #{product.daily_price.format}"
      puts "   Suggestion: Consider price adjustment or promotion"
      puts ""
    end
  end
end
```

## Customer Analytics

### Top Customers by Revenue
```ruby
ActsAsTenant.with_tenant(company) do
  period = 6.months

  puts "TOP 20 CUSTOMERS BY REVENUE"
  puts "Period: Last #{period / 1.month} months"
  puts "=" * 80
  puts ""

  top_customers = Client.joins(:bookings)
    .where("bookings.created_at >= ?", period.ago)
    .where("bookings.status IN (?)", [:paid, :completed])
    .group(:id)
    .select(
      "clients.*",
      "SUM(bookings.grand_total_cents) as total_revenue",
      "COUNT(bookings.id) as booking_count",
      "AVG(bookings.grand_total_cents) as avg_booking_value"
    )
    .order("total_revenue DESC")
    .limit(20)

  top_customers.each_with_index do |client, index|
    puts "#{index + 1}. #{client.name}"
    puts "   Email: #{client.email}"
    puts "   Total Revenue: $#{client.total_revenue / 100.0}"
    puts "   Bookings: #{client.booking_count}"
    puts "   Avg Booking: $#{client.avg_booking_value / 100.0}"
    puts "   Lifetime Value: $#{client.lifetime_value_cents / 100.0}" if client.lifetime_value_cents
    puts ""
  end
end
```

### Customer Booking Patterns
```ruby
ActsAsTenant.with_tenant(company) do
  puts "CUSTOMER BOOKING PATTERNS"
  puts "=" * 80
  puts ""

  # Bookings by day of week
  puts "Bookings by Start Day of Week:"
  day_counts = Booking.where("start_date >= ?", 3.months.ago)
    .group("EXTRACT(DOW FROM start_date)")
    .count

  ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'].each_with_index do |day, index|
    count = day_counts[index.to_f] || 0
    puts "  #{day}: #{count} bookings"
  end
  puts ""

  # Average booking duration
  avg_duration = Booking.where("start_date >= ?", 3.months.ago)
    .average("EXTRACT(DAY FROM (end_date - start_date))")
  puts "Average Booking Duration: #{avg_duration.to_f.round(2)} days"
  puts ""

  # Booking lead time (days in advance)
  avg_lead_time = Booking.where("created_at >= ?", 3.months.ago)
    .average("EXTRACT(DAY FROM (start_date - created_at))")
  puts "Average Lead Time: #{avg_lead_time.to_f.round(2)} days in advance"
  puts ""
end
```

## Inventory Reports

### Current Inventory Status
```ruby
ActsAsTenant.with_tenant(company) do
  puts "CURRENT INVENTORY STATUS"
  puts "=" * 80
  puts ""

  # Group by category
  Product.where(active: true).group(:category).count.each do |category, count|
    puts "#{category} (#{count} products):"

    Product.where(category: category, active: true).each do |product|
      # Current bookings
      current_bookings = BookingLineItem.joins(:booking)
        .where(bookable: product)
        .where("bookings.start_date <= ? AND bookings.end_date >= ?", Date.today, Date.today)
        .where("bookings.status IN (?)", [:confirmed, :paid, :in_progress])
        .sum(:quantity)

      available_now = product.quantity - current_bookings

      status_icon = available_now == 0 ? "🔴" : (available_now < product.quantity / 2 ? "🟡" : "🟢")

      puts "  #{status_icon} #{product.name}"
      puts "     Total: #{product.quantity} | Out: #{current_bookings} | Available: #{available_now}"
      puts "     Daily Price: #{product.daily_price.format}"

      # Upcoming bookings
      upcoming = BookingLineItem.joins(:booking)
        .where(bookable: product)
        .where("bookings.start_date > ?", Date.today)
        .where("bookings.status IN (?)", [:confirmed, :paid])
        .order("bookings.start_date")
        .limit(3)

      if upcoming.any?
        puts "     Upcoming: #{upcoming.first.booking.start_date} (#{upcoming.first.quantity} units)"
      end
    end
    puts ""
  end
end
```

### Stock Valuation Report
```ruby
ActsAsTenant.with_tenant(company) do
  puts "INVENTORY VALUATION REPORT"
  puts "=" * 80
  puts ""

  total_purchase_value = 0
  total_current_value = 0

  Product.group(:category).each do |category, products|
    category_purchase = 0
    category_current = 0

    puts "#{category}:"

    products.each do |product|
      # If product instances exist, use those
      if product.product_instances.any?
        purchase_value = product.product_instances.sum(:purchase_price_cents)
        current_value = product.product_instances.sum { |pi| pi.current_value || 0 }
      else
        # Estimate based on quantity
        purchase_value = 0
        current_value = product.quantity * product.daily_price_cents * 30  # Estimate: 30 days rental value
      end

      category_purchase += purchase_value
      category_current += current_value

      puts "  #{product.name}:"
      puts "    Quantity: #{product.quantity}"
      puts "    Purchase Value: $#{purchase_value / 100.0}"
      puts "    Estimated Value: $#{current_value / 100.0}"
    end

    total_purchase_value += category_purchase
    total_current_value += category_current

    puts "  Category Total: $#{category_current / 100.0}"
    puts ""
  end

  puts "Overall Total:"
  puts "  Purchase Value: $#{total_purchase_value / 100.0}"
  puts "  Current Value: $#{total_current_value / 100.0}"
end
```

## Accounts Receivable Reports

### AR Aging Report
```ruby
ActsAsTenant.with_tenant(company) do
  puts "ACCOUNTS RECEIVABLE AGING REPORT"
  puts "As of: #{Date.today.strftime('%Y-%m-%d')}"
  puts "=" * 80
  puts ""

  # Buckets: Current, 1-30, 31-60, 61-90, 90+
  buckets = {
    current: 0,
    days_1_30: 0,
    days_31_60: 0,
    days_61_90: 0,
    days_90_plus: 0
  }

  # Find unpaid bookings
  unpaid_bookings = Booking.where(status: [:confirmed, :in_progress])
    .where("payment_due_date IS NOT NULL")

  unpaid_bookings.each do |booking|
    days_overdue = (Date.today - booking.payment_due_date).to_i

    amount = booking.grand_total_cents

    if days_overdue <= 0
      buckets[:current] += amount
    elsif days_overdue <= 30
      buckets[:days_1_30] += amount
    elsif days_overdue <= 60
      buckets[:days_31_60] += amount
    elsif days_overdue <= 90
      buckets[:days_61_90] += amount
    else
      buckets[:days_90_plus] += amount
    end
  end

  total = buckets.values.sum

  puts "Aging Buckets:"
  puts "  Current: $#{buckets[:current] / 100.0}"
  puts "  1-30 Days: $#{buckets[:days_1_30] / 100.0}"
  puts "  31-60 Days: $#{buckets[:days_31_60] / 100.0}"
  puts "  61-90 Days: $#{buckets[:days_61_90] / 100.0}"
  puts "  90+ Days: $#{buckets[:days_90_plus] / 100.0}"
  puts ""
  puts "Total AR: $#{total / 100.0}"
  puts ""

  # Detailed list of overdue
  puts "Overdue Bookings (30+ days):"
  Booking.where(status: [:confirmed, :in_progress])
    .where("payment_due_date < ?", 30.days.ago)
    .order(:payment_due_date)
    .each do |booking|
      days_overdue = (Date.today - booking.payment_due_date).to_i
      puts "  #{booking.reference_number} - #{booking.customer_name}"
      puts "    Amount: #{booking.grand_total.format}"
      puts "    Due Date: #{booking.payment_due_date}"
      puts "    Days Overdue: #{days_overdue}"
      puts ""
    end
end
```

### Overdue Returns Report
```ruby
ActsAsTenant.with_tenant(company) do
  puts "OVERDUE RETURNS REPORT"
  puts "As of: #{Date.today.strftime('%Y-%m-%d')}"
  puts "=" * 80
  puts ""

  overdue_bookings = Booking.where("end_date < ?", Date.today)
    .where(status: [:confirmed, :paid, :in_progress])
    .order(:end_date)

  total_late_fees = 0

  overdue_bookings.each do |booking|
    days_overdue = (Date.today - booking.end_date).to_i

    puts "#{booking.reference_number} - #{booking.customer_name}"
    puts "  Expected Return: #{booking.end_date.strftime('%Y-%m-%d')}"
    puts "  Days Overdue: #{days_overdue}"
    puts "  Contact: #{booking.customer_email} / #{booking.customer_phone}"
    puts ""

    booking.booking_line_items.each do |item|
      late_fee = item.calculate_late_fees if item.respond_to?(:calculate_late_fees)
      if late_fee
        total_late_fees += late_fee.cents
        puts "    #{item.bookable.name} (#{item.quantity} units)"
        puts "      Late Fee: #{late_fee.format}"
      end
    end
    puts ""
  end

  puts "Total Late Fees: $#{total_late_fees / 100.0}"
end
```

## Data Export

### Export to CSV
```ruby
require 'csv'

ActsAsTenant.with_tenant(company) do
  # Export bookings
  CSV.open("bookings_export.csv", "w") do |csv|
    csv << [
      "Reference",
      "Customer Name",
      "Email",
      "Start Date",
      "End Date",
      "Status",
      "Subtotal",
      "Tax",
      "Total"
    ]

    Booking.where("created_at >= ?", 1.month.ago).each do |booking|
      csv << [
        booking.reference_number,
        booking.customer_name,
        booking.customer_email,
        booking.start_date,
        booking.end_date,
        booking.status,
        booking.subtotal&.format,
        booking.tax_total&.format,
        booking.grand_total&.format
      ]
    end
  end

  puts "Exported to bookings_export.csv"
end
```

## Best Practices

1. **Use tenant context**: Always wrap queries in `ActsAsTenant.with_tenant`
2. **Filter by date**: Use date ranges to limit query scope
3. **Index queries**: Ensure proper database indexes for common queries
4. **Cache results**: Cache expensive calculations
5. **Export large datasets**: Use CSV for large reports
6. **Schedule reports**: Run heavy reports during off-peak hours

## Related Skills
- rental-equipment-manager
- booking-workflow-manager
- multi-tenancy-manager
- api-tester
