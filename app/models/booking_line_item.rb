# app/models/booking_line_item.rb
class BookingLineItem < ApplicationRecord
  belongs_to :booking
  belongs_to :bookable, polymorphic: true

  # Product instance tracking
  has_many :booking_line_item_instances, dependent: :destroy
  has_many :product_instances, through: :booking_line_item_instances

  # Multi-location fulfillment
  belongs_to :fulfillment_location, class_name: "Location", optional: true
  belongs_to :pickup_location, class_name: "Location", optional: true
  belongs_to :delivery_location, class_name: "Location", optional: true
  belongs_to :location_transfer, optional: true
  belongs_to :delivered_by, class_name: "User", optional: true

  # Tax tracking
  belongs_to :tax_rate, optional: true

  # Monetize
  monetize :price_cents, as: :price, with_model_currency: :price_currency
  monetize :late_fee_cents, as: :late_fee, with_model_currency: :late_fee_currency
  monetize :delivery_cost_cents, as: :delivery_cost, with_model_currency: :delivery_cost_currency
  monetize :tax_amount_cents, as: :tax_amount, with_model_currency: :tax_amount_currency, allow_nil: true

  # Enums for workflow status (matching AdamRMS 0-110 scale)
  enum :workflow_status, {
    none: 0,
    pending_pick: 10,
    picked: 20,
    prepping: 30,
    tested: 40,
    packed: 50,
    dispatched: 60,
    awaiting_checkin: 70,
    case_opened: 80,
    unpacked: 90,
    tested_return: 100,
    stored: 110
  }, prefix: true

  enum :transfer_status, {
    no_transfer: 0,
    transfer_pending: 1,
    transfer_in_progress: 2,
    transfer_completed: 3,
    transfer_failed: 4
  }, prefix: true

  enum :delivery_method, {
    pickup: 0,           # Customer picks up
    delivery: 1,         # We deliver to customer
    shipping: 2,         # Ship via carrier (FedEx, UPS, etc.)
    courier: 3,          # Local courier service
    mail: 4,             # Postal service
    freight: 5,          # Freight shipping
    hand_delivery: 6     # Hand delivered by staff
  }, prefix: true

  enum :delivery_status, {
    not_scheduled: 0,    # No delivery scheduled yet
    scheduled: 1,        # Delivery scheduled
    preparing: 2,        # Being prepared for delivery
    ready: 3,            # Ready for pickup/delivery
    out_for_delivery: 4, # On the way
    delivered: 5,        # Successfully delivered
    failed: 6,           # Delivery failed
    returned: 7,         # Returned to sender
    cancelled: 8         # Delivery cancelled
  }, prefix: true

  # Validations
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :days, numericality: { greater_than: 0, only_integer: true }
  validates :price_currency, inclusion: { in: %w[NGN USD] }
  validates :discount_percent, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

  # Scopes
  scope :active, -> { where(deleted: false) }
  scope :by_status, ->(status) { where(workflow_status: status) if status.present? }
  scope :overdue, -> { where('expected_return_date < ? AND actual_return_date IS NULL', Time.current) }
  scope :returned, -> { where.not(actual_return_date: nil) }
  scope :returned_late, -> { where('actual_return_date > expected_return_date') }
  scope :pending_return, -> { where(actual_return_date: nil) }

  # Multi-location scopes
  scope :requiring_transfer, -> { where(requires_transfer: true) }
  scope :ready_for_pickup, -> { where.not(ready_for_pickup_at: nil).where(picked_at: nil) }
  scope :in_transit, -> { where.not(picked_at: nil).where(delivered_at: nil) }
  scope :delivered, -> { where.not(delivered_at: nil) }
  scope :pending_delivery, -> { where(delivered_at: nil) }
  scope :by_transfer_status, ->(status) { where(transfer_status: status) if status.present? }
  scope :at_location, ->(location_id) { where(fulfillment_location_id: location_id) }
  scope :for_delivery_to, ->(location_id) { where(delivery_location_id: location_id) }
  scope :late_deliveries, -> {
    joins(:location_transfer)
      .where('location_transfers.expected_arrival_at < ? AND booking_line_items.delivered_at IS NULL', Time.current)
  }

  # Delivery tracking scopes
  scope :by_delivery_method, ->(method) { where(delivery_method: method) if method.present? }
  scope :by_delivery_status, ->(status) { where(delivery_status: status) if status.present? }
  scope :scheduled_for_delivery, -> { where(delivery_status: [:scheduled, :preparing, :ready, :out_for_delivery]) }
  scope :delivered_successfully, -> { where(delivery_status: :delivered) }
  scope :failed_deliveries, -> { where(delivery_status: [:failed, :returned]) }
  scope :requires_signature, -> { where(signature_required: true, signature_captured_at: nil) }
  scope :delivery_window, ->(start_date, end_date) {
    where('delivery_start_date >= ? AND delivery_end_date <= ?', start_date, end_date)
  }
  scope :late_for_delivery, -> {
    where('delivery_end_date < ? AND delivery_status NOT IN (?)', Time.current, [statuses[:delivered], statuses[:cancelled]])
  }

  # Callbacks
  before_validation :set_price_from_bookable
  before_validation :set_days_from_booking

  # Calculate line total (with discount applied)
  # Uses dynamic pricing if bookable supports it
  def line_total
    subtotal = line_subtotal
    discount_amount = subtotal * (discount_percent / 100.0)
    subtotal - discount_amount
  end

  # Calculate line total without discount
  # Uses sophisticated pricing calculation if available
  def line_subtotal
    if use_dynamic_pricing?
      calculate_dynamic_price
    else
      price * quantity * days
    end
  end

  # Calculate price using bookable's sophisticated pricing rules
  def calculate_dynamic_price
    return Money.new(0, price_currency) unless bookable && booking

    if bookable.respond_to?(:calculate_rental_price)
      # Use Product's sophisticated pricing calculation
      calculated_price = bookable.calculate_rental_price(
        booking.start_date,
        booking.end_date,
        quantity
      )

      # Convert to Money object
      Money.new((calculated_price * 100).to_i, price_currency)
    else
      # Fallback to simple calculation
      price * quantity * days
    end
  end

  # Check if we should use dynamic pricing
  def use_dynamic_pricing?
    bookable.respond_to?(:calculate_rental_price) &&
      booking&.start_date.present? &&
      booking&.end_date.present?
  end

  # Recalculate price from bookable (call this when dates change or pricing rules change)
  def recalculate_price!
    if use_dynamic_pricing?
      calculated = calculate_dynamic_price
      update!(
        price_cents: (calculated.cents / quantity / days).to_i,
        price_currency: calculated.currency.to_s
      )
    else
      set_price_from_bookable
      save!
    end
  end

  # Get pricing breakdown for transparency
  def pricing_breakdown
    return nil unless use_dynamic_pricing?

    {
      base_price: price,
      quantity: quantity,
      days: days,
      subtotal: line_subtotal,
      discount_percent: discount_percent,
      discount_amount: line_subtotal * (discount_percent / 100.0),
      total: line_total,
      pricing_rules_applied: applicable_pricing_rules.map(&:name)
    }
  end

  # Get applicable pricing rules for this line item
  def applicable_pricing_rules
    return [] unless bookable.respond_to?(:pricing_rules) && booking

    bookable.pricing_rules.active.select do |rule|
      rule.applies_to?(booking.start_date, booking.end_date, days)
    end
  end

  # Soft delete
  def soft_delete!
    update(deleted: true)
  end

  # Workflow state transitions
  def advance_workflow!
    case workflow_status
    when "none" then workflow_status_pending_pick!
    when "pending_pick" then workflow_status_picked!
    when "picked" then workflow_status_prepping!
    when "prepping" then workflow_status_tested!
    when "tested" then workflow_status_packed!
    when "packed" then workflow_status_dispatched!
    when "dispatched" then workflow_status_awaiting_checkin!
    when "awaiting_checkin" then workflow_status_case_opened!
    when "case_opened" then workflow_status_unpacked!
    when "unpacked" then workflow_status_tested_return!
    when "tested_return" then workflow_status_stored!
    end
  end

  # Late Returns & Overdue Handling

  # Check if item is currently overdue (not yet returned and past expected return date)
  def overdue?
    expected_return_date.present? &&
      actual_return_date.nil? &&
      Time.current > expected_return_date
  end

  # Check if item was returned late (returned after expected date)
  def returned_late?
    actual_return_date.present? &&
      expected_return_date.present? &&
      actual_return_date > expected_return_date
  end

  # Calculate number of days overdue (0 if not overdue)
  def days_overdue
    return 0 unless overdue? || returned_late?

    end_date = actual_return_date || Time.current
    ((end_date - expected_return_date) / 1.day).ceil
  end

  # Calculate late fees based on product's late fee settings
  def calculate_late_fees
    return Money.new(0, late_fee_currency) unless overdue? || returned_late?
    return Money.new(0, late_fee_currency) unless bookable.respond_to?(:late_fee_cents)
    return Money.new(0, late_fee_currency) if bookable.late_fee_cents.nil? || bookable.late_fee_cents.zero?

    overdue_days = days_overdue
    return Money.new(0, late_fee_currency) if overdue_days <= 0

    late_fee_per_day = Money.new(bookable.late_fee_cents, bookable.late_fee_currency || 'USD')

    # Check if late fee is per day or flat rate based on bookable settings
    if bookable.respond_to?(:late_fee_type) && bookable.late_fee_type == 'flat'
      late_fee_per_day
    else
      # Per day calculation
      late_fee_per_day * overdue_days * quantity
    end
  end

  # Update late fee and days overdue (call this when marking as returned or periodically for overdue items)
  def update_late_fees!
    return unless overdue? || returned_late?

    calculated_fee = calculate_late_fees
    update!(
      late_fee_cents: calculated_fee.cents,
      late_fee_currency: calculated_fee.currency.to_s,
      days_overdue: days_overdue,
      late_fee_calculated_at: Time.current
    )
  end

  # Mark item as returned and calculate late fees if applicable
  def mark_as_returned!(return_date = Time.current)
    self.actual_return_date = return_date
    save!
    update_late_fees! if returned_late?
    actual_return_date
  end

  # Set expected return date (typically called when booking is confirmed)
  def set_expected_return_date!
    return unless booking&.end_date

    self.expected_return_date = booking.end_date
    save!
  end

  # Check if overdue notification has been sent
  def overdue_notification_sent?
    overdue_notified_at.present?
  end

  # Mark that overdue notification was sent
  def mark_overdue_notification_sent!
    update!(overdue_notified_at: Time.current)
  end

  # Get human-readable status
  def return_status
    if actual_return_date.present?
      returned_late? ? 'returned_late' : 'returned_on_time'
    elsif overdue?
      'overdue'
    elsif expected_return_date.present?
      'out_on_rental'
    else
      'pending'
    end
  end

  # Multi-Location Fulfillment Methods

  # Check if this line item requires a transfer between locations
  def needs_transfer?
    fulfillment_location_id.present? &&
      delivery_location_id.present? &&
      fulfillment_location_id != delivery_location_id
  end

  # Create a transfer for this line item
  def create_transfer!(from_location:, to_location:, user: nil, transfer_type: :internal, expected_arrival: nil, notes: nil)
    return false if location_transfer.present?
    return false unless from_location && to_location

    transfer = LocationTransfer.create!(
      from_location: from_location,
      to_location: to_location,
      initiated_by: user,
      booking_line_item: self,
      booking: booking,
      transfer_type: transfer_type,
      status: :pending,
      expected_arrival_at: expected_arrival,
      notes: notes
    )

    update!(
      location_transfer: transfer,
      requires_transfer: true,
      transfer_status: :transfer_pending
    )

    transfer
  end

  # Create delivery transfer (from fulfillment location to delivery location)
  def create_delivery_transfer!(user: nil, expected_arrival: nil, notes: nil)
    return false unless fulfillment_location && delivery_location

    create_transfer!(
      from_location: fulfillment_location,
      to_location: delivery_location,
      user: user,
      transfer_type: :delivery,
      expected_arrival: expected_arrival,
      notes: notes
    )
  end

  # Create pickup transfer (from pickup location to fulfillment/storage)
  def create_pickup_transfer!(to_location:, user: nil, expected_arrival: nil, notes: nil)
    return false unless pickup_location

    create_transfer!(
      from_location: pickup_location,
      to_location: to_location,
      user: user,
      transfer_type: :pickup,
      expected_arrival: expected_arrival,
      notes: notes
    )
  end

  # Mark item as ready for customer pickup
  def mark_ready_for_pickup!(user: nil)
    update!(
      ready_for_pickup_at: Time.current,
      workflow_status: :packed
    )
  end

  # Mark item as picked up by customer or delivery driver
  def mark_picked_up!(user: nil)
    update!(picked_at: Time.current)

    # If there's an active transfer, mark it as in transit
    if location_transfer&.status_pending?
      location_transfer.mark_in_transit!(user: user)
      update!(transfer_status: :transfer_in_progress)
    end
  end

  # Mark item as delivered to final destination
  def mark_delivered!(user: nil)
    update!(delivered_at: Time.current)

    # If there's an active transfer, complete it
    if location_transfer && !location_transfer.status_completed?
      location_transfer.mark_arrived!(user: user)
      location_transfer.complete!(user: user)
      update!(transfer_status: :transfer_completed)
    end
  end

  # Check if item is ready for pickup
  def ready_for_pickup?
    ready_for_pickup_at.present?
  end

  # Check if item has been picked up
  def picked_up?
    picked_at.present?
  end

  # Check if item has been delivered
  def delivered?
    delivered_at.present?
  end

  # Check if item is currently in transit
  def in_transit?
    picked_up? && !delivered? && location_transfer&.status_in_transit?
  end

  # Get current location status summary
  def location_status
    return 'delivered' if delivered?
    return 'in_transit' if in_transit?
    return 'ready_for_pickup' if ready_for_pickup?
    return 'preparing' if workflow_status_packed? || workflow_status_tested?
    'pending'
  end

  # Get estimated delivery date
  def estimated_delivery_date
    return delivered_at if delivered?
    location_transfer&.expected_arrival_at
  end

  # Check if delivery is late
  def delivery_late?
    return false if delivered?
    return false unless estimated_delivery_date

    Time.current > estimated_delivery_date
  end

  # Days until expected delivery
  def days_until_delivery
    return 0 if delivered?
    return nil unless estimated_delivery_date

    ((estimated_delivery_date - Time.current) / 1.day).ceil
  end

  # Cancel active transfer
  def cancel_transfer!(reason: nil, user: nil)
    return false unless location_transfer

    location_transfer.cancel!(reason: reason, user: user)
    update!(
      transfer_status: :transfer_failed,
      requires_transfer: false
    )
  end

  # Get full location journey (for tracking display)
  def location_journey
    journey = []

    if fulfillment_location
      journey << {
        location: fulfillment_location,
        type: 'fulfillment',
        status: 'origin',
        timestamp: created_at
      }
    end

    if pickup_location
      journey << {
        location: pickup_location,
        type: 'pickup',
        status: picked_up? ? 'completed' : 'pending',
        timestamp: picked_at
      }
    end

    if delivery_location
      journey << {
        location: delivery_location,
        type: 'delivery',
        status: delivered? ? 'completed' : (in_transit? ? 'in_transit' : 'pending'),
        timestamp: delivered_at || estimated_delivery_date
      }
    end

    journey
  end

  # Delivery Tracking Methods

  # Schedule delivery
  def schedule_delivery!(start_date:, end_date:, method:, cost: nil, notes: nil)
    update!(
      delivery_start_date: start_date,
      delivery_end_date: end_date,
      delivery_method: method,
      delivery_cost_cents: cost ? (cost * 100).to_i : 0,
      delivery_status: :scheduled,
      delivery_notes: notes
    )
  end

  # Update delivery status with workflow
  def advance_delivery_status!(user: nil)
    case delivery_status
    when 'not_scheduled'
      update!(delivery_status: :scheduled)
    when 'scheduled'
      update!(delivery_status: :preparing)
    when 'preparing'
      update!(delivery_status: :ready)
    when 'ready'
      update!(delivery_status: :out_for_delivery)
    when 'out_for_delivery'
      complete_delivery!(user: user)
    end
  end

  # Mark as ready for delivery
  def mark_ready_for_delivery!(user: nil)
    update!(
      delivery_status: :ready,
      ready_for_pickup_at: Time.current
    )
  end

  # Mark as out for delivery
  def mark_out_for_delivery!(tracking: nil, carrier: nil, user: nil)
    updates = {
      delivery_status: :out_for_delivery,
      picked_at: Time.current
    }
    updates[:delivery_tracking_number] = tracking if tracking.present?
    updates[:delivery_carrier] = carrier if carrier.present?

    update!(updates)
  end

  # Complete delivery
  def complete_delivery!(user: nil, signature_captured: false)
    updates = {
      delivery_status: :delivered,
      delivered_at: Time.current
    }
    updates[:delivered_by] = user if user.present?
    updates[:signature_captured_at] = Time.current if signature_captured

    update!(updates)
  end

  # Mark delivery as failed
  def fail_delivery!(reason: nil, user: nil)
    notes = delivery_notes.to_s
    notes += "\nFailed: #{reason} at #{Time.current}" if reason.present?

    update!(
      delivery_status: :failed,
      delivery_notes: notes
    )
  end

  # Cancel delivery
  def cancel_delivery!(reason: nil)
    notes = delivery_notes.to_s
    notes += "\nCancelled: #{reason} at #{Time.current}" if reason.present?

    update!(
      delivery_status: :cancelled,
      delivery_notes: notes
    )
  end

  # Check if delivery is late
  def delivery_late?
    return false if delivery_status_delivered? || delivery_status_cancelled?
    return false unless delivery_end_date.present?

    Time.current > delivery_end_date
  end

  # Days until delivery window
  def days_until_delivery_window
    return 0 if delivery_end_date.nil?
    return 0 if delivery_status_delivered?

    ((delivery_end_date - Time.current) / 1.day).ceil
  end

  # Check if delivery window is active
  def in_delivery_window?
    return false unless delivery_start_date && delivery_end_date

    Time.current.between?(delivery_start_date, delivery_end_date)
  end

  # Check if signature is required but not captured
  def needs_signature?
    signature_required? && signature_captured_at.nil?
  end

  # Capture signature
  def capture_signature!(user: nil)
    return false unless signature_required?

    update!(signature_captured_at: Time.current)
  end

  # Calculate delivery cost based on method and distance
  def calculate_delivery_cost
    return Money.new(0, delivery_cost_currency) if delivery_method_pickup?

    # Base cost by method
    base_cost = case delivery_method
    when 'hand_delivery'
      50.00 # $50 base for hand delivery
    when 'courier'
      30.00 # $30 for local courier
    when 'delivery'
      40.00 # $40 for standard delivery
    when 'shipping'
      calculate_shipping_cost # Use carrier rates
    when 'freight'
      calculate_freight_cost # Use freight rates
    when 'mail'
      15.00 # $15 for mail
    else
      0.00
    end

    Money.new((base_cost * 100).to_i, delivery_cost_currency)
  end

  # Get delivery time remaining
  def delivery_time_remaining
    return nil unless delivery_end_date
    return '0 minutes' if delivery_status_delivered?

    diff = delivery_end_date - Time.current
    return 'Overdue' if diff < 0

    if diff < 1.hour
      "#{(diff / 60).to_i} minutes"
    elsif diff < 1.day
      "#{(diff / 3600).to_i} hours"
    else
      "#{(diff / 86400).to_i} days"
    end
  end

  # Get human-readable delivery status
  def delivery_status_display
    case delivery_status
    when 'not_scheduled'
      'Not Scheduled'
    when 'scheduled'
      "Scheduled for #{delivery_start_date.strftime('%b %d')}"
    when 'preparing'
      'Being Prepared'
    when 'ready'
      'Ready for Pickup/Delivery'
    when 'out_for_delivery'
      tracking_info = delivery_tracking_number.present? ? " (#{delivery_tracking_number})" : ''
      "Out for Delivery#{tracking_info}"
    when 'delivered'
      "Delivered on #{delivered_at.strftime('%b %d at %I:%M %p')}"
    when 'failed'
      'Delivery Failed'
    when 'returned'
      'Returned to Sender'
    when 'cancelled'
      'Delivery Cancelled'
    end
  end

  # Check if requires delivery (not pickup)
  def requires_delivery?
    !delivery_method_pickup?
  end

  # ============================================================================
  # TAX CALCULATION (Public methods)
  # ============================================================================

  # Calculate tax for this line item
  def calculate_tax
    # Default to taxable unless explicitly marked as non-taxable
    self.taxable = true if taxable.nil?

    # If not taxable, set tax to 0
    unless taxable?
      self.tax_amount_cents = 0
      self.tax_amount_currency = price_currency
      return Money.new(0, price_currency)
    end

    # Get the tax rate to use
    rate = effective_tax_rate
    return Money.new(0, price_currency) unless rate

    # Calculate tax on line total (after discount)
    tax_cents = rate.calculate_tax(line_total.cents, price_currency)

    self.tax_amount_cents = tax_cents
    self.tax_amount_currency = price_currency
    self.tax_rate = rate

    Money.new(tax_cents, price_currency)
  end

  # Get the effective tax rate for this line item
  def effective_tax_rate
    # 1. Use explicitly assigned tax rate
    return tax_rate if tax_rate.present?

    # 2. Use booking's default tax rate
    return booking.default_tax_rate if booking&.default_tax_rate.present?

    # 3. Look up tax rate based on booking location
    return nil unless booking&.venue_location

    # Get the first applicable tax rate for the location
    applicable_rates = booking.applicable_tax_rates
    applicable_rates.first
  end

  # Total including tax
  def line_total_with_tax
    line_total + (tax_amount || Money.new(0, price_currency))
  end

  # Get tax breakdown for this line item
  def tax_breakdown
    {
      line_subtotal: line_subtotal,
      discount: line_subtotal - line_total,
      line_total: line_total,
      taxable: taxable?,
      tax_rate: tax_rate&.display_name,
      tax_rate_percentage: tax_rate&.display_rate,
      tax_amount: tax_amount,
      total_with_tax: line_total_with_tax
    }
  end

  private

  # Calculate shipping cost based on carrier rates
  def calculate_shipping_cost
    # Placeholder - integrate with carrier APIs
    # Would use weight, dimensions, destination, etc.
    75.00 # Default $75 for shipping
  end

  # Calculate freight cost
  def calculate_freight_cost
    # Placeholder - integrate with freight broker APIs
    250.00 # Default $250 for freight
  end

  def set_price_from_bookable
    return unless bookable
    self.price = bookable.daily_price
  end

  def set_days_from_booking
    return unless booking
    self.days = booking.rental_days
  end
end
