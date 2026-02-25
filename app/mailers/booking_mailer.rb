class BookingMailer < ApplicationMailer
  default from: 'bookings@rentable.app'

  # Send booking confirmation email
  def confirmation(booking)
    @booking = booking
    @customer_name = booking.customer_name
    @reference_number = booking.reference_number
    @start_date = booking.start_date.strftime('%B %d, %Y')
    @end_date = booking.end_date.strftime('%B %d, %Y')
    @total_price = booking.total_price.format
    @line_items = booking.booking_line_items.includes(:bookable)

    mail(
      to: booking.customer_email,
      subject: "Booking Confirmation - #{@reference_number}"
    )
  end

  # Send payment success email
  def payment_success(booking)
    @booking = booking
    @customer_name = booking.customer_name
    @reference_number = booking.reference_number
    @start_date = booking.start_date.strftime('%B %d, %Y')
    @end_date = booking.end_date.strftime('%B %d, %Y')
    @total_price = booking.total_price.format
    @line_items = booking.booking_line_items.includes(:bookable)

    mail(
      to: booking.customer_email,
      subject: "Payment Received - #{@reference_number}"
    )
  end

  # Send booking reminder email (2 days before start)
  def reminder(booking)
    @booking = booking
    @customer_name = booking.customer_name
    @reference_number = booking.reference_number
    @start_date = booking.start_date.strftime('%B %d, %Y at %I:%M %p')
    @end_date = booking.end_date.strftime('%B %d, %Y at %I:%M %p')
    @delivery_start = booking.delivery_start_date&.strftime('%B %d, %Y at %I:%M %p')
    @venue = booking.venue_location&.name
    @line_items = booking.booking_line_items.includes(:bookable)

    mail(
      to: booking.customer_email,
      subject: "Reminder: Your booking starts in 2 days - #{@reference_number}"
    )
  end

  # Send invoice ready email
  def invoice_ready(booking)
    @booking = booking
    @customer_name = booking.customer_name
    @reference_number = booking.reference_number
    @total_price = booking.total_price.format
    @total_paid = Money.new(booking.total_payments_received, booking.total_price_currency).format
    @balance_due = Money.new(booking.balance_due, booking.total_price_currency).format

    mail(
      to: booking.customer_email,
      subject: "Invoice Ready - #{@reference_number}"
    )
  end

  # Send payment received notification
  def payment_received(booking, payment)
    @booking = booking
    @payment = payment
    @customer_name = booking.customer_name
    @reference_number = booking.reference_number
    @payment_amount = payment.amount.format
    @payment_date = payment.payment_date&.strftime('%B %d, %Y')
    @balance_due = Money.new(booking.balance_due, booking.total_price_currency).format

    mail(
      to: booking.customer_email,
      subject: "Payment Received - #{@payment_amount} - #{@reference_number}"
    )
  end

  # Send booking cancellation email
  def cancellation(booking)
    @booking = booking
    @customer_name = booking.customer_name
    @reference_number = booking.reference_number
    @start_date = booking.start_date.strftime('%B %d, %Y')
    @end_date = booking.end_date.strftime('%B %d, %Y')

    mail(
      to: booking.customer_email,
      subject: "Booking Cancelled - #{@reference_number}"
    )
  end
end
