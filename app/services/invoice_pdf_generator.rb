# app/services/invoice_pdf_generator.rb
require 'prawn'
require 'prawn/table'

class InvoicePdfGenerator
  def initialize(booking)
    @booking = booking
    @pdf = Prawn::Document.new
  end

  def generate
    add_header
    add_booking_details
    add_line_items_table
    add_payment_summary
    add_footer

    @pdf.render
  end

  private

  def add_header
    @pdf.text "INVOICE", size: 30, style: :bold, align: :center
    @pdf.move_down 10
    @pdf.text "Rentable", size: 20, align: :center
    @pdf.move_down 5
    @pdf.text "Professional Equipment Rental", size: 12, align: :center
    @pdf.move_down 20
  end

  def add_booking_details
    @pdf.text "Invoice #: #{@booking.reference_number}", size: 14, style: :bold
    @pdf.move_down 5

    details = [
      ["Date:", Time.current.strftime("%B %d, %Y")],
      ["Customer:", @booking.customer_name],
      ["Email:", @booking.customer_email],
      ["Phone:", @booking.customer_phone],
      ["Rental Period:", "#{@booking.start_date.strftime("%b %d, %Y")} - #{@booking.end_date.strftime("%b %d, %Y")}"],
      ["Duration:", "#{@booking.rental_days} days"]
    ]

    if @booking.client
      details << ["Client:", @booking.client.name]
    end

    if @booking.venue_location
      details << ["Venue:", @booking.venue_location.name]
    end

    @pdf.table(details, cell_style: { borders: [] }) do
      column(0).font_style = :bold
      column(0).width = 120
    end

    @pdf.move_down 20
  end

  def add_line_items_table
    @pdf.text "Items", size: 16, style: :bold
    @pdf.move_down 10

    table_data = [["Item", "Qty", "Days", "Rate/Day", "Subtotal", "Discount", "Total"]]

    @booking.booking_line_items.each do |item|
      discount_text = item.discount_percent > 0 ? "#{item.discount_percent}%" : "-"

      table_data << [
        item.bookable.name,
        item.quantity.to_s,
        item.days.to_s,
        item.price.format,
        Money.new(item.price_cents * item.quantity * item.days, item.price_currency).format,
        discount_text,
        item.line_total.format
      ]
    end

    @pdf.table(table_data, header: true, width: @pdf.bounds.width) do
      row(0).font_style = :bold
      row(0).background_color = 'EEEEEE'
      columns(1..6).align = :right
      self.row_colors = ['FFFFFF', 'F9F9F9']
      self.column_widths = [200, 40, 40, 70, 80, 60, 80]
    end

    @pdf.move_down 20
  end

  def add_payment_summary
    subtotal = Money.new(@booking.total_price_cents, @booking.total_price_currency)
    paid = Money.new(@booking.total_payments_received, @booking.total_price_currency)
    balance = Money.new(@booking.balance_due, @booking.total_price_currency)

    summary_data = [
      ["Subtotal:", subtotal.format],
      ["Total Paid:", paid.format],
      ["Balance Due:", balance.format]
    ]

    @pdf.table(summary_data, position: :right, width: 250) do
      column(0).font_style = :bold
      column(1).align = :right
      row(2).font_style = :bold
      row(2).background_color = 'FFEB3B'
    end

    @pdf.move_down 20
  end

  def add_footer
    @pdf.move_down 30

    if @booking.invoice_notes.present?
      @pdf.text "Notes:", style: :bold
      @pdf.text @booking.invoice_notes
      @pdf.move_down 15
    end

    @pdf.text "Thank you for your business!", align: :center, style: :italic
    @pdf.move_down 10

    # Add page numbers
    page_count = @pdf.page_count
    @pdf.number_pages "Page <page> of #{page_count}",
                     at: [@pdf.bounds.right - 150, 0],
                     width: 150,
                     align: :right,
                     size: 10
  end
end
