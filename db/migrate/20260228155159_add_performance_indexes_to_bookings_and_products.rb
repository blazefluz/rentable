class AddPerformanceIndexesToBookingsAndProducts < ActiveRecord::Migration[8.1]
  def change
    # ========================================================================
    # BOOKINGS TABLE - Performance Indexes
    # ========================================================================

    # Critical: Date range queries for availability checking
    # Query: Find bookings overlapping a date range
    # Usage: BookingService.calculate_availability, Calendar views
    add_index :bookings, [:company_id, :start_date, :end_date],
              name: 'idx_bookings_company_date_range',
              comment: 'Optimizes date range queries for availability'

    # Critical: Customer booking history and dashboard
    # Query: Get all bookings for a client, sorted by date
    # Usage: Client dashboard, booking history
    add_index :bookings, [:client_id, :start_date],
              name: 'idx_bookings_client_start_date',
              comment: 'Customer booking history queries'

    # Important: Status-based queries with company scoping
    # Query: Find all confirmed/pending bookings for a company
    # Usage: Reports, dashboard, order fulfillment
    add_index :bookings, [:company_id, :status, :start_date],
              name: 'idx_bookings_company_status_date',
              comment: 'Status filtering with date sorting'

    # Important: Quote workflow queries
    # Query: Find active quotes that haven't expired
    # Usage: Quote follow-up, sales pipeline
    add_index :bookings, [:company_id, :quote_status, :quote_expires_at],
              name: 'idx_bookings_company_quote_status',
              where: 'quote_status IS NOT NULL',
              comment: 'Quote management queries'

    # Important: Accounts Receivable queries
    # Query: Find overdue bookings by payment due date
    # Usage: AR aging reports, payment collection
    add_index :bookings, [:company_id, :payment_due_date, :days_past_due],
              name: 'idx_bookings_ar_overdue',
              where: 'payment_due_date IS NOT NULL',
              comment: 'AR aging and collection queries'

    # Important: Lead source analytics
    # Query: Track booking sources for marketing ROI
    # Usage: Marketing reports, campaign analytics
    add_index :bookings, [:company_id, :lead_source],
              name: 'idx_bookings_lead_source',
              where: "lead_source IS NOT NULL AND lead_source != ''",
              comment: 'Lead source tracking for marketing'

    # ========================================================================
    # PRODUCTS TABLE - Performance Indexes
    # ========================================================================

    # Critical: Product catalog filtering
    # Query: Get active products by category for a company
    # Usage: Product catalog, booking form product selection
    add_index :products, [:company_id, :category, :active],
              name: 'idx_products_company_category_active',
              comment: 'Product catalog filtering'

    # Note: Barcode already has a unique index in the schema, so we don't need to add another one

    # Important: Maintenance tracking
    # Query: Find products needing maintenance
    # Usage: Maintenance dashboard, scheduling
    add_index :products, [:company_id, :maintenance_status],
              name: 'idx_products_maintenance_status',
              where: 'maintenance_status IS NOT NULL',
              comment: 'Maintenance tracking queries'

    # Important: Inventory management
    # Query: Find products with low stock
    # Usage: Inventory reports, reorder alerts
    add_index :products, [:company_id, :stock_on_hand],
              name: 'idx_products_inventory_stock',
              where: 'tracks_inventory = true',
              comment: 'Inventory tracking queries'

    # Important: Product type filtering
    # Query: Filter products by type (rental, sale, service)
    # Usage: Product lists, reports
    add_index :products, [:company_id, :item_type, :active],
              name: 'idx_products_company_item_type',
              comment: 'Product type filtering'

    # ========================================================================
    # PAYMENTS TABLE - Performance Indexes
    # ========================================================================

    # Important: Booking payment queries with status
    # Query: Get payments for a booking by status
    # Usage: Payment reconciliation, refund processing
    add_index :payments, [:booking_id, :payment_type, :payment_date],
              name: 'idx_payments_booking_type_date',
              comment: 'Booking payment history'

    # ========================================================================
    # USERS TABLE - Performance Indexes
    # ========================================================================

    # Important: Company user lookup by role
    # Query: Find all admins/managers for a company
    # Usage: Permission checks, user management
    add_index :users, [:company_id, :role],
              name: 'idx_users_company_role',
              comment: 'Company user role queries'

    # ========================================================================
    # BOOKING_LINE_ITEMS TABLE - Performance Indexes
    # ========================================================================

    # Critical: Bookable polymorphic queries
    # Query: Find all line items for a product/kit
    # Usage: Product rental history, utilization reports
    add_index :booking_line_items, [:bookable_type, :bookable_id, :booking_id],
              name: 'idx_booking_line_items_bookable',
              comment: 'Polymorphic bookable association queries'

    # Important: Tax calculation queries
    # Query: Get taxable line items for a booking
    # Usage: Tax calculation, reporting
    add_index :booking_line_items, [:booking_id, :taxable],
              name: 'idx_booking_line_items_taxable',
              comment: 'Tax calculation queries'
  end
end
