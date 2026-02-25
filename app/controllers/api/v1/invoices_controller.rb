# app/controllers/api/v1/invoices_controller.rb
class Api::V1::InvoicesController < ApplicationController
  before_action :set_booking

  # GET /api/v1/bookings/:booking_id/invoice
  # Get invoice details as JSON
  def show
    render json: invoice_json
  end

  # GET /api/v1/bookings/:booking_id/invoice.pdf
  # Download invoice as PDF
  def download
    pdf = InvoicePdfGenerator.new(@booking).generate

    send_data pdf,
              filename: "invoice_#{@booking.reference_number}.pdf",
              type: 'application/pdf',
              disposition: 'attachment'
  end

  # GET /api/v1/bookings/:booking_id/invoice/preview
  # Preview invoice as PDF in browser
  def preview
    pdf = InvoicePdfGenerator.new(@booking).generate

    send_data pdf,
              filename: "invoice_#{@booking.reference_number}.pdf",
              type: 'application/pdf',
              disposition: 'inline'
  end

  # POST /api/v1/bookings/:booking_id/invoice/email
  # Email invoice to customer
  def email
    pdf = InvoicePdfGenerator.new(@booking).generate

    # Attach PDF and send email
    BookingMailer.invoice_ready(@booking).tap do |mail|
      mail.attachments["invoice_#{@booking.reference_number}.pdf"] = pdf
    end.deliver_later

    render json: {
      message: "Invoice emailed to #{@booking.customer_email}",
      sent_at: Time.current
    }
  end

  # POST /api/v1/bookings/:booking_id/invoice/generate
  # Manually trigger invoice generation and update booking
  def generate
    # Mark invoice as generated
    @booking.update(invoice_notes: params[:notes]) if params[:notes].present?

    # Generate PDF
    pdf = InvoicePdfGenerator.new(@booking).generate

    # Optionally email it
    if params[:send_email]
      BookingMailer.invoice_ready(@booking).tap do |mail|
        mail.attachments["invoice_#{@booking.reference_number}.pdf"] = pdf
      end.deliver_later
    end

    render json: {
      message: "Invoice generated successfully",
      invoice: invoice_json,
      emailed: params[:send_email] || false
    }
  end

  private

  def set_booking
    @booking = Booking.includes(:booking_line_items, :payments, :client, :venue_location).find(params[:booking_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Booking not found" }, status: :not_found
  end

  def invoice_json
    {
      booking_id: @booking.id,
      reference_number: @booking.reference_number,
      invoice_date: @booking.created_at,
      customer: {
        name: @booking.customer_name,
        email: @booking.customer_email,
        phone: @booking.customer_phone
      },
      client: @booking.client ? {
        name: @booking.client.name,
        email: @booking.client.email
      } : nil,
      rental_period: {
        start: @booking.start_date,
        end: @booking.end_date,
        days: @booking.rental_days
      },
      venue: @booking.venue_location ? {
        name: @booking.venue_location.name,
        address: @booking.venue_location.address
      } : nil,
      line_items: @booking.booking_line_items.map do |item|
        {
          item: item.bookable.name,
          quantity: item.quantity,
          days: item.days,
          rate_per_day: item.price.format,
          subtotal: Money.new(item.price_cents * item.quantity * item.days, item.price_currency).format,
          discount: "#{item.discount_percent}%",
          total: item.line_total.format
        }
      end,
      financial_summary: {
        subtotal: @booking.total_price.format,
        total_paid: Money.new(@booking.total_payments_received, @booking.total_price_currency).format,
        balance_due: Money.new(@booking.balance_due, @booking.total_price_currency).format,
        fully_paid: @booking.fully_paid?
      },
      payments: @booking.payments.where(payment_type: :payment_received).map do |payment|
        {
          date: payment.payment_date,
          amount: payment.amount.format,
          method: payment.payment_method,
          reference: payment.reference
        }
      end,
      notes: @booking.invoice_notes
    }
  end
end
