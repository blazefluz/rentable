class Api::V1::InsuranceCertificatesController < ApplicationController
  before_action :set_product
  before_action :set_insurance_certificate, only: [:show, :update, :destroy]

  def index
    @certificates = @product.insurance_certificates.where(deleted: false)
    render json: @certificates
  end

  def show
    render json: @certificate
  end

  def create
    @certificate = @product.insurance_certificates.new(insurance_certificate_params)

    if @certificate.save
      render json: @certificate, status: :created
    else
      render json: { errors: @certificate.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @certificate.update(insurance_certificate_params)
      render json: @certificate
    else
      render json: { errors: @certificate.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @certificate.update(deleted: true)
    render json: { message: 'Insurance certificate deleted successfully' }
  end

  private

  def set_product
    @product = Product.find(params[:product_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Product not found' }, status: :not_found
  end

  def set_insurance_certificate
    @certificate = @product.insurance_certificates.where(deleted: false).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Insurance certificate not found' }, status: :not_found
  end

  def insurance_certificate_params
    params.require(:insurance_certificate).permit(
      :policy_number,
      :provider,
      :coverage_amount_cents,
      :coverage_amount_currency,
      :start_date,
      :end_date,
      :certificate_file,
      :notes
    )
  end
end
