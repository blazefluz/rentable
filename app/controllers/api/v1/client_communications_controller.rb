class Api::V1::ClientCommunicationsController < ApplicationController
  before_action :set_client, only: [:index, :create]
  before_action :set_communication, only: [:show, :update, :destroy]

  # GET /api/v1/clients/:client_id/communications
  def index
    @communications = @client.client_communications.recent
    @communications = @communications.by_type(params[:type]) if params[:type]
    @communications = @communications.since(params[:since]) if params[:since]
    @communications = @communications.page(params[:page]).per(params[:per_page] || 25)

    render json: @communications
  end

  # GET /api/v1/client_communications/:id
  def show
    render json: @communication
  end

  # POST /api/v1/clients/:client_id/communications
  def create
    @communication = @client.client_communications.build(communication_params)
    @communication.user = current_user
    @communication.communicated_at ||= Time.current

    if @communication.save
      render json: @communication, status: :created
    else
      render json: { errors: @communication.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/client_communications/:id
  def update
    if @communication.update(communication_params)
      render json: @communication
    else
      render json: { errors: @communication.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/client_communications/:id
  def destroy
    @communication.destroy
    head :no_content
  end

  private

  def set_client
    @client = Client.find(params[:client_id])
  end

  def set_communication
    @communication = ClientCommunication.find(params[:id])
  end

  def communication_params
    params.require(:client_communication).permit(
      :communication_type, :direction, :subject, :notes,
      :contact_id, :communicated_at, :attachment
    )
  end
end
