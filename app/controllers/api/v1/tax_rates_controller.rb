class Api::V1::TaxRatesController < ApplicationController
  before_action :set_tax_rate, only: [:show, :update, :destroy]

  # GET /api/v1/tax_rates
  def index
    @tax_rates = TaxRate.all

    # Filter by country
    @tax_rates = @tax_rates.by_country(params[:country]) if params[:country].present?

    # Filter by state
    @tax_rates = @tax_rates.by_state(params[:state]) if params[:state].present?

    # Filter by active status
    @tax_rates = @tax_rates.active if params[:active] == 'true'

    # Filter by current (within date range)
    @tax_rates = @tax_rates.current if params[:current] == 'true'

    # Filter by tax type
    @tax_rates = @tax_rates.where(tax_type: params[:tax_type]) if params[:tax_type].present?

    @tax_rates = @tax_rates.ordered

    render json: @tax_rates, status: :ok
  end

  # GET /api/v1/tax_rates/:id
  def show
    render json: @tax_rate, status: :ok
  end

  # POST /api/v1/tax_rates
  def create
    @tax_rate = TaxRate.new(tax_rate_params)

    if @tax_rate.save
      render json: @tax_rate, status: :created
    else
      render json: { errors: @tax_rate.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/tax_rates/:id
  def update
    if @tax_rate.update(tax_rate_params)
      render json: @tax_rate, status: :ok
    else
      render json: { errors: @tax_rate.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/tax_rates/:id
  def destroy
    @tax_rate.destroy
    head :no_content
  end

  # GET /api/v1/tax_rates/for_location
  # Get applicable tax rates for a specific location
  def for_location
    country = params[:country] || 'US'
    state = params[:state]
    city = params[:city]
    zip = params[:zip]

    @tax_rates = TaxRate.for_location(
      country: country,
      state: state,
      city: city,
      zip: zip
    )

    render json: @tax_rates, status: :ok
  end

  # POST /api/v1/tax_rates/:id/calculate
  # Calculate tax for a given amount
  def calculate
    set_tax_rate
    amount_cents = params[:amount_cents].to_i
    currency = params[:currency] || 'USD'

    tax_cents = @tax_rate.calculate_tax(amount_cents, currency)
    tax_amount = Money.new(tax_cents, currency)

    render json: {
      tax_rate: @tax_rate,
      amount: Money.new(amount_cents, currency),
      tax_amount: tax_amount,
      total: Money.new(amount_cents + tax_cents, currency),
      calculation_method: @tax_rate.calculation_method,
      rate: @tax_rate.display_rate
    }, status: :ok
  end

  private

  def set_tax_rate
    @tax_rate = TaxRate.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Tax rate not found' }, status: :not_found
  end

  def tax_rate_params
    params.require(:tax_rate).permit(
      :name,
      :tax_code,
      :tax_type,
      :calculation_method,
      :rate,
      :rate_cents,
      :country,
      :state,
      :city,
      :zip_code_pattern,
      :active,
      :start_date,
      :end_date,
      :applies_to_shipping,
      :applies_to_deposits,
      :minimum_amount_cents,
      :maximum_amount_cents,
      :compound,
      :position
    )
  end
end
