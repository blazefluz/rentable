class Api::V1::QrCodesController < ApplicationController
  # QR code generation for products, locations, bookings, etc.
  # Public endpoint - no authentication required for generating codes
  skip_before_action :authenticate_user!

  # GET /api/v1/qr_codes/generate
  # Generate QR code for any data (barcode, serial number, URL, etc.)
  def generate
    data = params[:data]

    unless data.present?
      return render json: { error: 'Data parameter is required' }, status: :bad_request
    end

    begin
      # Get format and size parameters first
      format = params[:format]&.downcase || 'png'
      size = params[:size]&.to_i || 300

      # Load required gems
      require 'rqrcode'
      require 'chunky_png' if format == 'png'

      # Generate QR code with high error correction
      qr = RQRCode::QRCode.new(data, level: :h)

      case format
      when 'svg'
        # Generate SVG
        svg = qr.as_svg(
          offset: 0,
          color: '000',
          shape_rendering: 'crispEdges',
          module_size: 6,
          standalone: true
        )
        send_data svg, type: 'image/svg+xml', disposition: 'inline'
      when 'png'
        # Generate PNG
        png = qr.as_png(
          bit_depth: 1,
          border_modules: 4,
          color_mode: ChunkyPNG::COLOR_GRAYSCALE,
          color: 'black',
          file: nil,
          fill: 'white',
          module_px_size: 6,
          resize_exactly_to: size,
          resize_gte_to: false,
          size: size
        )
        send_data png.to_s, type: 'image/png', disposition: 'inline'
      when 'txt'
        # Generate ASCII text representation
        txt = qr.to_s
        render plain: txt
      else
        render json: { error: 'Invalid format. Use png, svg, or txt' }, status: :bad_request
      end
    rescue StandardError => e
      if e.class.name.include?("QRCodeRunTimeError")
        render json: { error: "QR code generation failed: #{e.message}" }, status: :unprocessable_entity
      else
        render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error
      end
    end
  end

  # GET /api/v1/qr_codes/product/:id
  # Generate QR code for a product barcode
  def product
    product = Product.find(params[:id])

    if product.barcode.blank?
      return render json: { error: 'Product has no barcode' }, status: :not_found
    end

    redirect_to api_v1_qr_code_generate_path(
      data: product.barcode,
      format: params[:format] || 'png',
      size: params[:size] || 300
    )
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Product not found' }, status: :not_found
  end

  # GET /api/v1/qr_codes/product_instance/:id
  # Generate QR code for a product instance serial number
  def product_instance
    instance = ProductInstance.find(params[:id])

    data = instance.serial_number || instance.asset_tag
    if data.blank?
      return render json: { error: 'Product instance has no serial number or asset tag' }, status: :not_found
    end

    redirect_to api_v1_qr_code_generate_path(
      data: data,
      format: params[:format] || 'png',
      size: params[:size] || 300
    )
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Product instance not found' }, status: :not_found
  end

  # GET /api/v1/qr_codes/location/:id
  # Generate QR code for a location barcode
  def location
    location = Location.find(params[:id])

    if location.barcode.blank?
      return render json: { error: 'Location has no barcode' }, status: :not_found
    end

    redirect_to api_v1_qr_code_generate_path(
      data: location.barcode,
      format: params[:format] || 'png',
      size: params[:size] || 300
    )
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Location not found' }, status: :not_found
  end

  # GET /api/v1/qr_codes/booking/:id
  # Generate QR code for a booking reference number
  def booking
    booking = Booking.find(params[:id])

    if booking.reference_number.blank?
      return render json: { error: 'Booking has no reference number' }, status: :not_found
    end

    redirect_to api_v1_qr_code_generate_path(
      data: booking.reference_number,
      format: params[:format] || 'png',
      size: params[:size] || 300
    )
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Booking not found' }, status: :not_found
  end
end
