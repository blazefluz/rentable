class Api::V1::ClientTagsController < ApplicationController
  before_action :set_tag, only: [:show, :update, :destroy]

  # GET /api/v1/client_tags
  def index
    @tags = ClientTag.all
    @tags = @tags.active if params[:active] == 'true'
    @tags = @tags.alphabetical unless params[:sort] == 'usage'
    @tags = @tags.by_usage if params[:sort] == 'usage'

    render json: @tags.map { |tag|
      tag.as_json.merge(
        usage_count: tag.usage_count,
        clients_count: tag.clients_count
      )
    }
  end

  # GET /api/v1/client_tags/:id
  def show
    render json: @tag.as_json.merge(
      usage_count: @tag.usage_count,
      clients_count: @tag.clients_count,
      clients: @tag.clients.limit(10)
    )
  end

  # POST /api/v1/client_tags
  def create
    @tag = ClientTag.new(tag_params)

    if @tag.save
      render json: @tag, status: :created
    else
      render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/client_tags/:id
  def update
    if @tag.update(tag_params)
      render json: @tag
    else
      render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/client_tags/:id
  def destroy
    @tag.destroy
    head :no_content
  end

  private

  def set_tag
    @tag = ClientTag.find(params[:id])
  end

  def tag_params
    params.require(:client_tag).permit(:name, :color, :description, :icon, :active)
  end
end
