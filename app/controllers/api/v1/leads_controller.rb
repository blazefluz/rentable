class Api::V1::LeadsController < ApplicationController
  before_action :set_lead, only: [:show, :update, :destroy, :convert, :mark_lost]

  # GET /api/v1/leads
  def index
    @leads = Lead.all
    @leads = @leads.active if params[:active] == 'true'
    @leads = @leads.open if params[:open] == 'true'
    @leads = @leads.by_source(params[:source]) if params[:source]
    @leads = @leads.assigned_to_user(params[:assigned_to]) if params[:assigned_to]
    @leads = @leads.closing_soon if params[:closing_soon] == 'true'
    @leads = @leads.overdue if params[:overdue] == 'true'
    @leads = @leads.high_value if params[:high_value] == 'true'
    @leads = @leads.recent
    @leads = @leads.page(params[:page]).per(params[:per_page] || 25)

    render json: @leads
  end

  # GET /api/v1/leads/:id
  def show
    render json: @lead, include: [:assigned_to, :converted_to_client]
  end

  # POST /api/v1/leads
  def create
    @lead = Lead.new(lead_params)

    if @lead.save
      render json: @lead, status: :created
    else
      render json: { errors: @lead.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/leads/:id
  def update
    if @lead.update(lead_params)
      render json: @lead
    else
      render json: { errors: @lead.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/leads/:id
  def destroy
    @lead.destroy
    head :no_content
  end

  # POST /api/v1/leads/:id/convert
  def convert
    client_id = params[:client_id]
    client = client_id.present? ? Client.find(client_id) : nil

    begin
      converted_client = @lead.convert_to_client!(client)
      render json: {
        lead: @lead,
        client: converted_client,
        message: "Lead successfully converted to client"
      }, status: :ok
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/leads/:id/mark_lost
  def mark_lost
    reason = params[:reason]

    if @lead.mark_as_lost!(reason)
      render json: @lead, status: :ok
    else
      render json: { errors: @lead.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_lead
    @lead = Lead.find(params[:id])
  end

  def lead_params
    params.require(:lead).permit(
      :name, :email, :phone, :company, :source, :status,
      :expected_value_cents, :expected_value_currency,
      :probability, :expected_close_date, :assigned_to_id,
      :notes
    )
  end
end
