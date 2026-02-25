class Api::V1::ContractsController < ApplicationController
  before_action :set_contract, only: [:show, :update, :destroy, :sign, :request_signature, :generate_pdf, :void, :send_reminders]
  before_action :set_booking, only: [:create], if: -> { params[:booking_id].present? }

  # GET /api/v1/contracts
  def index
    @contracts = Contract.where(deleted: false)

    # Filter by booking
    @contracts = @contracts.for_booking(params[:booking_id]) if params[:booking_id].present?

    # Filter by type
    @contracts = @contracts.by_type(params[:contract_type]) if params[:contract_type].present?

    # Filter by status
    @contracts = @contracts.where(status: params[:status]) if params[:status].present?

    # Filter templates
    @contracts = @contracts.templates if params[:templates] == 'true'

    # Filter pending signatures
    @contracts = @contracts.pending_signatures if params[:pending_signatures] == 'true'

    render json: @contracts.as_json(
      include: {
        booking: { only: [:id, :reference_number, :customer_name] },
        contract_signatures: {
          only: [:id, :signer_name, :signer_email, :signer_role, :signed_at, :accepted_terms],
          methods: [:signed?, :time_since_signed]
        }
      },
      methods: [:signing_progress, :fully_signed?, :expired?]
    )
  end

  # GET /api/v1/contracts/:id
  def show
    render json: @contract.as_json(
      include: {
        booking: { only: [:id, :reference_number, :customer_name, :start_date, :end_date] },
        contract_signatures: {
          only: [:id, :signer_name, :signer_email, :signer_role, :signature_type, :signed_at, :accepted_terms, :witness_name],
          methods: [:signed?, :time_since_signed]
        }
      },
      methods: [:signing_progress, :fully_signed?, :expired?, :effective?, :pending_signers]
    )
  end

  # POST /api/v1/contracts
  def create
    if params[:from_template].present?
      @contract = Contract.create_from_template(
        params[:template_name],
        booking: @booking,
        variables: params[:variables] || {}
      )
    else
      @contract = Contract.new(contract_params)
      @contract.booking = @booking if @booking
    end

    if @contract && @contract.persisted? || @contract.save
      render json: {
        success: true,
        message: 'Contract created successfully',
        contract: @contract.as_json(methods: [:signing_progress])
      }, status: :created
    else
      render json: {
        success: false,
        errors: @contract ? @contract.errors.full_messages : ['Failed to create contract']
      }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/contracts/:id
  def update
    if @contract.update(contract_params)
      render json: {
        success: true,
        message: 'Contract updated successfully',
        contract: @contract
      }
    else
      render json: {
        success: false,
        errors: @contract.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/contracts/:id
  def destroy
    @contract.soft_delete!
    render json: {
      success: true,
      message: 'Contract deleted successfully'
    }
  end

  # POST /api/v1/contracts/:id/sign
  def sign
    signature = @contract.contract_signatures.find_by(signer_email: params[:signer_email])

    unless signature
      return render json: {
        success: false,
        error: 'Signature request not found for this email'
      }, status: :not_found
    end

    if signature.sign!(
      signature_data: params[:signature_data],
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      accept_terms: params[:accept_terms] != false
    )
      render json: {
        success: true,
        message: 'Contract signed successfully',
        contract: @contract.reload.as_json(methods: [:signing_progress, :fully_signed?]),
        signature: signature.as_json(methods: [:signed?, :time_since_signed])
      }
    else
      render json: {
        success: false,
        errors: signature.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/contracts/:id/request_signature
  def request_signature
    signature = @contract.request_signature(
      signer_name: params[:signer_name],
      signer_email: params[:signer_email],
      signer_role: params[:signer_role],
      user: current_user
    )

    if signature.persisted?
      # Send email notification
      ContractMailer.signature_request(@contract, signature).deliver_later

      render json: {
        success: true,
        message: 'Signature request sent successfully',
        signature: signature
      }
    else
      render json: {
        success: false,
        errors: signature.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/contracts/:id/generate_pdf
  def generate_pdf
    begin
      filepath = @contract.generate_pdf!

      send_file filepath,
        filename: "contract_#{@contract.id}.pdf",
        type: 'application/pdf',
        disposition: 'attachment'
    rescue => e
      render json: {
        success: false,
        error: "Failed to generate PDF: #{e.message}"
      }, status: :internal_server_error
    end
  end

  # POST /api/v1/contracts/:id/void
  def void
    @contract.void!(reason: params[:reason])
    render json: {
      success: true,
      message: 'Contract voided successfully',
      contract: @contract
    }
  end

  # POST /api/v1/contracts/:id/send_reminders
  def send_reminders
    @contract.send_signature_reminders!
    render json: {
      success: true,
      message: 'Reminders sent to pending signers',
      pending_count: @contract.pending_signers.count
    }
  end

  # GET /api/v1/contracts/templates
  def templates
    @templates = Contract.templates
    render json: @templates.as_json(only: [:id, :template_name, :title, :contract_type, :version])
  end

  private

  def set_contract
    @contract = Contract.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Contract not found' }, status: :not_found
  end

  def set_booking
    @booking = Booking.find(params[:booking_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Booking not found' }, status: :not_found
  end

  def contract_params
    params.require(:contract).permit(
      :title, :content, :contract_type, :version, :effective_date, :expiry_date,
      :status, :terms_url, :requires_signature, :template, :template_name,
      variables: {}
    )
  end

  def current_user
    # Placeholder - implement your authentication logic
    nil
  end
end
