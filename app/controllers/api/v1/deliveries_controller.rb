class Api::V1::DeliveriesController < ApplicationController
  before_action :set_line_item, except: [:index, :scheduled, :late]

  # GET /api/v1/deliveries
  # List all deliveries with optional filters
  def index
    @line_items = BookingLineItem.all

    # Filter by delivery status
    if params[:status].present?
      @line_items = @line_items.by_delivery_status(params[:status])
    end

    # Filter by delivery method
    if params[:method].present?
      @line_items = @line_items.by_delivery_method(params[:method])
    end

    # Filter by date range
    if params[:start_date].present? && params[:end_date].present?
      @line_items = @line_items.delivery_window(params[:start_date], params[:end_date])
    end

    # Show only items that require delivery
    if params[:requires_delivery] == 'true'
      @line_items = @line_items.where.not(delivery_method: BookingLineItem.delivery_methods[:pickup])
    end

    render json: @line_items.as_json(
      include: {
        booking: { only: [:id, :reference_number, :customer_name] },
        delivery_location: { only: [:id, :name, :address] },
        delivered_by: { only: [:id, :name, :email] }
      },
      methods: [:delivery_status_display, :delivery_time_remaining, :delivery_late?]
    )
  end

  # GET /api/v1/deliveries/scheduled
  # Get all scheduled deliveries
  def scheduled
    @line_items = BookingLineItem.scheduled_for_delivery
    render json: @line_items.as_json(
      include: { booking: { only: [:id, :reference_number, :customer_name] } },
      methods: [:delivery_status_display, :days_until_delivery_window]
    )
  end

  # GET /api/v1/deliveries/late
  # Get all late deliveries
  def late
    @line_items = BookingLineItem.late_for_delivery
    render json: @line_items.as_json(
      include: { booking: { only: [:id, :reference_number, :customer_name] } },
      methods: [:delivery_status_display, :days_until_delivery_window]
    )
  end

  # POST /api/v1/booking_line_items/:id/schedule_delivery
  # Schedule a delivery for a line item
  def schedule
    if @line_item.schedule_delivery!(
      start_date: params[:start_date],
      end_date: params[:end_date],
      method: params[:method],
      cost: params[:cost]&.to_f,
      notes: params[:notes]
    )
      render json: {
        success: true,
        message: 'Delivery scheduled successfully',
        line_item: @line_item.as_json(methods: [:delivery_status_display])
      }, status: :ok
    else
      render json: {
        success: false,
        errors: @line_item.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/booking_line_items/:id/advance_delivery
  # Advance delivery to next status
  def advance
    @line_item.advance_delivery_status!
    render json: {
      success: true,
      message: "Delivery status advanced to #{@line_item.delivery_status}",
      line_item: @line_item.as_json(methods: [:delivery_status_display])
    }, status: :ok
  end

  # PATCH /api/v1/booking_line_items/:id/mark_ready
  # Mark delivery as ready
  def mark_ready
    @line_item.mark_ready_for_delivery!
    render json: {
      success: true,
      message: 'Delivery marked as ready',
      line_item: @line_item.as_json(methods: [:delivery_status_display])
    }, status: :ok
  end

  # PATCH /api/v1/booking_line_items/:id/mark_out_for_delivery
  # Mark as out for delivery
  def mark_out_for_delivery
    @line_item.mark_out_for_delivery!(
      tracking: params[:tracking_number],
      carrier: params[:carrier]
    )
    render json: {
      success: true,
      message: 'Marked as out for delivery',
      line_item: @line_item.as_json(methods: [:delivery_status_display])
    }, status: :ok
  end

  # POST /api/v1/booking_line_items/:id/complete_delivery
  # Mark delivery as completed
  def complete_delivery
    signature_captured = params[:signature_captured] == 'true' || params[:signature_captured] == true

    @line_item.complete_delivery!(
      signature_captured: signature_captured
    )

    render json: {
      success: true,
      message: 'Delivery completed successfully',
      line_item: @line_item.as_json(methods: [:delivery_status_display])
    }, status: :ok
  end

  # POST /api/v1/booking_line_items/:id/fail_delivery
  # Mark delivery as failed
  def fail_delivery
    @line_item.fail_delivery!(reason: params[:reason])
    render json: {
      success: true,
      message: 'Delivery marked as failed',
      line_item: @line_item.as_json(methods: [:delivery_status_display])
    }, status: :ok
  end

  # DELETE /api/v1/booking_line_items/:id/cancel_delivery
  # Cancel a delivery
  def cancel_delivery
    @line_item.cancel_delivery!(reason: params[:reason])
    render json: {
      success: true,
      message: 'Delivery cancelled',
      line_item: @line_item.as_json(methods: [:delivery_status_display])
    }, status: :ok
  end

  # POST /api/v1/booking_line_items/:id/capture_signature
  # Capture delivery signature
  def capture_signature
    if @line_item.capture_signature!
      render json: {
        success: true,
        message: 'Signature captured',
        line_item: @line_item
      }, status: :ok
    else
      render json: {
        success: false,
        message: 'Signature not required or already captured'
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/booking_line_items/:id/delivery_cost
  # Calculate delivery cost
  def calculate_cost
    cost = @line_item.calculate_delivery_cost
    render json: {
      cost: cost.format,
      cost_cents: cost.cents,
      currency: cost.currency.to_s,
      method: @line_item.delivery_method
    }, status: :ok
  end

  private

  def set_line_item
    @line_item = BookingLineItem.find(params[:id] || params[:booking_line_item_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Line item not found' }, status: :not_found
  end
end
