# Delivery Tracking & Background Jobs - Implementation Complete ✅

## Overview
Implemented comprehensive delivery tracking system with delivery dates, methods, costs, status workflow, and background jobs for overdue notifications and recurring booking generation.

---

## 1. Delivery Tracking System

### Database Migration
**File:** `db/migrate/20260225221806_add_delivery_tracking_to_booking_line_items.rb`

Added 12 fields to `booking_line_items` table:
- `delivery_start_date` - Start of delivery window
- `delivery_end_date` - End of delivery window (deadline)
- `delivery_method` - Enum: pickup, delivery, shipping, courier, mail, freight, hand_delivery
- `delivery_cost_cents` - Cost of delivery in cents
- `delivery_cost_currency` - Currency for delivery cost
- `delivery_status` - Enum: 9 statuses (not_scheduled → delivered)
- `delivery_notes` - Free-text notes about delivery
- `delivery_tracking_number` - Tracking number from carrier
- `delivery_carrier` - Carrier name (FedEx, UPS, etc.)
- `signature_required` - Boolean flag for signature requirement
- `signature_captured_at` - When signature was captured
- `delivered_by_id` - Reference to User who delivered

**Indexes:**
- `delivery_method`
- `delivery_status`
- `delivery_start_date`
- `delivery_tracking_number`
- `delivered_by_id` (foreign key)

---

### Delivery Method Enum (7 types)

```ruby
enum :delivery_method, {
  pickup: 0,           # Customer picks up
  delivery: 1,         # We deliver to customer
  shipping: 2,         # Ship via carrier (FedEx, UPS, etc.)
  courier: 3,          # Local courier service
  mail: 4,             # Postal service
  freight: 5,          # Freight shipping
  hand_delivery: 6     # Hand delivered by staff
}
```

---

### Delivery Status Enum (9 statuses)

```ruby
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
}
```

**Workflow:**
```
not_scheduled → scheduled → preparing → ready → out_for_delivery → delivered
                                                                   ↓
                                                                 failed/returned
```

---

### Delivery Methods (16 methods)

**Scheduling & Workflow:**
- `schedule_delivery!(start_date:, end_date:, method:, cost:, notes:)` - Schedule a delivery
- `advance_delivery_status!(user:)` - Advance to next status in workflow
- `mark_ready_for_delivery!(user:)` - Mark as ready for pickup/delivery
- `mark_out_for_delivery!(tracking:, carrier:, user:)` - Mark as out for delivery
- `complete_delivery!(user:, signature_captured:)` - Mark as delivered
- `fail_delivery!(reason:, user:)` - Mark as failed
- `cancel_delivery!(reason:)` - Cancel delivery

**Status Checks:**
- `delivery_late?` - Check if delivery is past end date
- `days_until_delivery_window` - Days until delivery deadline
- `in_delivery_window?` - Check if currently in delivery window
- `requires_delivery?` - Check if not pickup method

**Signature Management:**
- `needs_signature?` - Check if signature required but not captured
- `capture_signature!(user:)` - Capture delivery signature

**Cost & Display:**
- `calculate_delivery_cost` - Calculate cost based on method
- `delivery_time_remaining` - Human-readable time until deadline
- `delivery_status_display` - Human-readable status

---

### Delivery Scopes (8 scopes)

```ruby
# Filter by method/status
BookingLineItem.by_delivery_method(:shipping)
BookingLineItem.by_delivery_status(:out_for_delivery)

# Status groups
BookingLineItem.scheduled_for_delivery  # scheduled, preparing, ready, out_for_delivery
BookingLineItem.delivered_successfully  # delivered
BookingLineItem.failed_deliveries       # failed, returned

# Special filters
BookingLineItem.requires_signature      # signature required but not captured
BookingLineItem.delivery_window(start_date, end_date)  # deliveries in date range
BookingLineItem.late_for_delivery       # past delivery_end_date and not delivered/cancelled
```

---

### Delivery Cost Calculation

Base costs by method:
- **Pickup:** $0 (customer picks up)
- **Hand Delivery:** $50
- **Delivery:** $40
- **Courier:** $30
- **Shipping:** $75 (placeholder for carrier API integration)
- **Freight:** $250 (placeholder for freight broker API)
- **Mail:** $15

Methods for future enhancement:
- `calculate_shipping_cost` - Integrate with FedEx/UPS APIs
- `calculate_freight_cost` - Integrate with freight broker APIs

---

## 2. API Endpoints

### BookingLineItems Controller

Added 9 delivery endpoints to `Api::V1::BookingLineItemsController`:

```
POST   /api/v1/bookings/:booking_id/line_items/:id/schedule_delivery
PATCH  /api/v1/bookings/:booking_id/line_items/:id/advance_delivery
PATCH  /api/v1/bookings/:booking_id/line_items/:id/mark_ready
PATCH  /api/v1/bookings/:booking_id/line_items/:id/mark_out_for_delivery
POST   /api/v1/bookings/:booking_id/line_items/:id/complete_delivery
POST   /api/v1/bookings/:booking_id/line_items/:id/fail_delivery
DELETE /api/v1/bookings/:booking_id/line_items/:id/cancel_delivery
POST   /api/v1/bookings/:booking_id/line_items/:id/capture_signature
GET    /api/v1/bookings/:booking_id/line_items/:id/delivery_cost
```

### Deliveries Controller

New controller `Api::V1::DeliveriesController` with 3 collection endpoints:

```
GET /api/v1/deliveries              # List all deliveries with filters
GET /api/v1/deliveries/scheduled    # All scheduled deliveries
GET /api/v1/deliveries/late         # All late deliveries
```

**Query Parameters for `/api/v1/deliveries`:**
- `status` - Filter by delivery_status
- `method` - Filter by delivery_method
- `start_date` & `end_date` - Filter by delivery window
- `requires_delivery` - Show only non-pickup items

---

## 3. Background Jobs

### SendOverdueNotificationsJob

**File:** `app/jobs/send_overdue_notifications_job.rb`

**Purpose:** Send notifications for overdue returns and late deliveries

**What it does:**
1. **Initial Overdue Notifications** - Find items past `expected_return_date` that haven't been notified
2. **Overdue Reminders** - Send reminders for items still overdue after 3+ days
3. **Late Delivery Notifications** - Notify about deliveries past `delivery_end_date`

**Tracks notifications via:**
- `overdue_notified_at` - When first overdue notification sent
- `last_overdue_reminder_sent_at` - When last reminder sent
- `delivery_late_notified_at` - When late delivery notification sent

**Schedule:** Run daily via cron job

**Mailer methods required:**
- `BookingMailer.overdue_notification(line_item)`
- `BookingMailer.overdue_reminder(line_item)`
- `BookingMailer.late_delivery_notification(line_item)`

---

### GenerateRecurringBookingsJob

**File:** `app/jobs/generate_recurring_bookings_job.rb`

**Purpose:** Auto-generate bookings from recurring booking series

**What it does:**
1. Find active recurring bookings where `next_occurrence <= Time.current`
2. Check if `max_occurrences` reached → complete series if yes
3. Call `recurring_booking.generate_next_booking!`
4. Send notification email if `notify_on_generation` is true
5. Log successes and failures

**Schedule:** Run hourly or every 15 minutes via cron job

**Mailer method required:**
- `BookingMailer.recurring_booking_created(booking)`

---

## 4. Usage Examples

### Schedule a Delivery

```ruby
line_item = BookingLineItem.find(123)

line_item.schedule_delivery!(
  start_date: Date.today + 2.days,
  end_date: Date.today + 3.days,
  method: :shipping,
  cost: 75.00,
  notes: "Handle with care - fragile equipment"
)

# Set tracking info when shipped
line_item.mark_out_for_delivery!(
  tracking: "1Z999AA10123456784",
  carrier: "FedEx"
)

# Complete delivery
line_item.complete_delivery!(
  signature_captured: true
)
```

### Check Delivery Status

```ruby
# Is delivery late?
line_item.delivery_late?  # => true/false

# Time remaining
line_item.delivery_time_remaining  # => "2 days" or "5 hours" or "Overdue"

# Human-readable status
line_item.delivery_status_display  # => "Out for Delivery (1Z999AA10123456784)"

# In delivery window?
line_item.in_delivery_window?  # => true if between start_date and end_date
```

### Query Deliveries

```ruby
# All scheduled deliveries
BookingLineItem.scheduled_for_delivery

# Late deliveries needing attention
BookingLineItem.late_for_delivery

# Deliveries requiring signatures
BookingLineItem.requires_signature

# Deliveries this week
BookingLineItem.delivery_window(Date.today, Date.today + 7.days)

# By method
BookingLineItem.by_delivery_method(:shipping)

# By status
BookingLineItem.by_delivery_status(:out_for_delivery)
```

### API Usage

```bash
# Schedule delivery
curl -X POST http://localhost:3000/api/v1/bookings/1/line_items/5/schedule_delivery \
  -H "Content-Type: application/json" \
  -d '{
    "start_date": "2026-02-27T09:00:00",
    "end_date": "2026-02-27T17:00:00",
    "method": "delivery",
    "cost": 40.00,
    "notes": "Call before delivery"
  }'

# Mark out for delivery
curl -X PATCH http://localhost:3000/api/v1/bookings/1/line_items/5/mark_out_for_delivery \
  -H "Content-Type: application/json" \
  -d '{
    "tracking_number": "1Z999AA10123456784",
    "carrier": "FedEx"
  }'

# Complete delivery with signature
curl -X POST http://localhost:3000/api/v1/bookings/1/line_items/5/complete_delivery \
  -H "Content-Type: application/json" \
  -d '{"signature_captured": true}'

# Get all late deliveries
curl http://localhost:3000/api/v1/deliveries/late

# Calculate delivery cost
curl http://localhost:3000/api/v1/bookings/1/line_items/5/delivery_cost
```

---

## 5. Cron Job Setup

Add to `config/schedule.rb` (if using whenever gem):

```ruby
# Send overdue notifications daily at 8 AM
every 1.day, at: '8:00 am' do
  runner "SendOverdueNotificationsJob.perform_later"
end

# Generate recurring bookings every hour
every 1.hour do
  runner "GenerateRecurringBookingsJob.perform_later"
end
```

Or use Heroku Scheduler, Sidekiq Cron, or native cron:

```bash
# Crontab entries
0 8 * * * cd /path/to/app && bin/rails runner "SendOverdueNotificationsJob.perform_now"
0 * * * * cd /path/to/app && bin/rails runner "GenerateRecurringBookingsJob.perform_now"
```

---

## 6. Integration Points

### With Multi-Location Fulfillment

The delivery tracking system integrates with the existing multi-location fulfillment:

```ruby
# Create transfer AND schedule delivery
line_item.create_delivery_transfer!(
  expected_arrival: 2.days.from_now,
  notes: "Rush delivery"
)

line_item.schedule_delivery!(
  start_date: 2.days.from_now,
  end_date: 2.days.from_now + 4.hours,
  method: :delivery,
  cost: 40.00
)

# When marked as picked up, both systems update
line_item.mark_picked_up!  # Updates transfer status AND delivery status
```

### With Late Returns

The overdue notification job handles both:
- Late returns (items past `expected_return_date`)
- Late deliveries (deliveries past `delivery_end_date`)

---

## 7. Future Enhancements

1. **Carrier API Integration**
   - Real-time tracking via FedEx/UPS APIs
   - Auto-update delivery status from carrier webhooks
   - Calculate accurate shipping costs based on weight/dimensions

2. **Route Optimization**
   - Optimize delivery routes for hand_delivery method
   - Group deliveries by geographic area
   - Assign drivers to optimal routes

3. **Delivery Windows**
   - Allow customers to select preferred delivery windows
   - Send SMS notifications when driver is nearby
   - Provide real-time tracking link

4. **Proof of Delivery**
   - Photo capture at delivery
   - Digital signature capture with touch/stylus
   - GPS coordinates of delivery location

5. **Delivery Analytics**
   - On-time delivery percentage
   - Average delivery cost by method
   - Carrier performance comparison
   - Delivery success rate by area

---

## Summary

**Delivery Tracking:**
- ✅ 12 database fields
- ✅ 7 delivery methods
- ✅ 9 delivery statuses with workflow
- ✅ 16 model methods
- ✅ 8 scopes for querying
- ✅ Cost calculation with carrier placeholders
- ✅ Signature capture functionality

**API:**
- ✅ 9 line item delivery endpoints
- ✅ 3 deliveries collection endpoints
- ✅ Complete REST interface

**Background Jobs:**
- ✅ Overdue notifications job
- ✅ Recurring bookings generation job
- ✅ Error handling and logging
- ✅ Ready for cron scheduling

**Total Implementation:**
- 1 migration
- 2 enums (7 methods + 9 statuses)
- 16 methods
- 8 scopes
- 12 API endpoints
- 2 background jobs
- Full documentation
