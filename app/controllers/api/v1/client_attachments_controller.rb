# app/controllers/api/v1/client_attachments_controller.rb
class Api::V1::ClientAttachmentsController < ApplicationController
  before_action :set_client

  # GET /api/v1/clients/:client_id/attachments
  def index
    render json: {
      attachments: @client.attachments.map { |attachment| attachment_json(attachment) },
      count: @client.attachments.count
    }
  end

  # POST /api/v1/clients/:client_id/attachments
  def create
    if params[:files].present?
      @client.attachments.attach(params[:files])

      render json: {
        message: "#{params[:files].count} file(s) uploaded successfully",
        attachments: @client.attachments.map { |attachment| attachment_json(attachment) }
      }, status: :created
    else
      render json: { error: "No files provided" }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/clients/:client_id/attachments/:id
  def destroy
    attachment = @client.attachments.find(params[:id])
    attachment.purge

    render json: { message: "Attachment deleted successfully" }
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Attachment not found" }, status: :not_found
  end

  private

  def set_client
    @client = Client.find(params[:client_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Client not found" }, status: :not_found
  end

  def attachment_json(attachment)
    {
      id: attachment.id,
      filename: attachment.filename.to_s,
      content_type: attachment.content_type,
      byte_size: attachment.byte_size,
      url: url_for(attachment),
      created_at: attachment.created_at
    }
  end
end
