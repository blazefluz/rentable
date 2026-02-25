class Api::V1::PricingRulesController < ApplicationController
  before_action :set_pricing_rule, only: [:show, :update, :destroy]

  def index
    @rules = PricingRule.active.includes(:product, :product_type).by_priority
    render json: @rules.as_json(include: { product: { only: [:id, :name] }, product_type: { only: [:id, :name] } })
  end

  def show
    render json: @rule.as_json(include: { product: { only: [:id, :name] }, product_type: { only: [:id, :name] } })
  end

  def create
    @rule = PricingRule.new(pricing_rule_params)

    if @rule.save
      render json: @rule, status: :created
    else
      render json: { errors: @rule.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @rule.update(pricing_rule_params)
      render json: @rule
    else
      render json: { errors: @rule.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @rule.update(deleted: true)
    render json: { message: 'Pricing rule deleted successfully' }
  end

  private

  def set_pricing_rule
    @rule = PricingRule.active.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Pricing rule not found' }, status: :not_found
  end

  def pricing_rule_params
    params.require(:pricing_rule).permit(
      :product_id,
      :product_type_id,
      :rule_type,
      :name,
      :start_date,
      :end_date,
      :day_of_week,
      :min_days,
      :max_days,
      :discount_percentage,
      :price_override_cents,
      :price_override_currency,
      :active,
      :priority
    )
  end
end
