class Api::V1::ContactsController < ApplicationController
  before_action :set_client, only: [:index, :create]
  before_action :set_contact, only: [:show, :update, :destroy]

  # GET /api/v1/clients/:client_id/contacts
  def index
    @contacts = @client.contacts
    @contacts = @contacts.primary if params[:primary] == 'true'
    @contacts = @contacts.decision_makers if params[:decision_makers] == 'true'

    render json: @contacts
  end

  # GET /api/v1/contacts/:id
  def show
    render json: @contact
  end

  # POST /api/v1/clients/:client_id/contacts
  def create
    @contact = @client.contacts.build(contact_params)

    if @contact.save
      render json: @contact, status: :created
    else
      render json: { errors: @contact.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/contacts/:id
  def update
    if @contact.update(contact_params)
      render json: @contact
    else
      render json: { errors: @contact.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/contacts/:id
  def destroy
    @contact.destroy
    head :no_content
  end

  private

  def set_client
    @client = Client.find(params[:client_id])
  end

  def set_contact
    @contact = Contact.find(params[:id])
  end

  def contact_params
    params.require(:contact).permit(
      :first_name, :last_name, :title, :email, :phone, :mobile,
      :is_primary, :decision_maker, :receives_invoices, :notes
    )
  end
end
