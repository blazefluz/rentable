class Api::V1::CompaniesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:signup, :create, :check_subdomain]
  skip_before_action :set_current_tenant, only: [:signup, :create, :check_subdomain], if: :method_defined?(:set_current_tenant)
  before_action :set_company, only: [:show, :update, :settings, :branding]
  before_action :authorize_company_admin, only: [:update, :settings, :branding]

  # POST /api/v1/companies/signup
  # Public endpoint for company registration
  def signup
    @company = Company.new(signup_params)

    if @company.save
      # Create admin user for the company
      admin_user = @company.users.create!(
        name: params[:admin_name],
        email: params[:admin_email],
        password: params[:admin_password],
        password_confirmation: params[:admin_password],
        role: :admin,
        email_verified_at: Time.current
      )

      # Generate token for the admin user
      token = admin_user.generate_jwt

      render json: {
        company: company_response(@company),
        user: user_response(admin_user),
        token: token,
        message: 'Company created successfully. Welcome to Rentable!'
      }, status: :created
    else
      render json: {
        errors: @company.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # Alias for signup
  def create
    signup
  end

  # GET /api/v1/companies/check_subdomain?subdomain=acme
  # Check if subdomain is available
  def check_subdomain
    subdomain = params[:subdomain].to_s.downcase.strip

    if subdomain.blank?
      return render json: { available: false, message: 'Subdomain cannot be blank' }
    end

    if Company::RESERVED_SUBDOMAINS.include?(subdomain)
      return render json: { available: false, message: 'This subdomain is reserved' }
    end

    if subdomain.length < 3 || subdomain.length > 63
      return render json: { available: false, message: 'Subdomain must be between 3 and 63 characters' }
    end

    unless subdomain.match?(/\A[a-z0-9][a-z0-9\-]*[a-z0-9]\z/)
      return render json: { available: false, message: 'Subdomain can only contain letters, numbers, and hyphens' }
    end

    available = !Company.exists?(['LOWER(subdomain) = ?', subdomain])

    render json: {
      available: available,
      message: available ? 'Subdomain is available' : 'Subdomain is already taken',
      suggested: available ? nil : generate_suggestions(subdomain)
    }
  end

  # GET /api/v1/companies/current
  def show
    render json: {
      company: company_response(@company)
    }
  end

  # PATCH /api/v1/companies/current
  def update
    if @company.update(update_params)
      render json: {
        company: company_response(@company),
        message: 'Company updated successfully'
      }
    else
      render json: {
        errors: @company.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/companies/settings
  def settings
    render json: {
      settings: @company.settings,
      branding: @company.branding,
      subscription: {
        tier: @company.subscription_tier,
        status: @company.status,
        trial_ends_at: @company.trial_ends_at,
        trial_days_remaining: @company.trial_days_remaining,
        features: available_features
      },
      limits: {
        max_users: @company.max_users,
        current_users: @company.users.active.count,
        max_products: @company.max_products,
        current_products: @company.products.active.count,
        max_bookings_per_month: @company.max_bookings_per_month
      }
    }
  end

  # PATCH /api/v1/companies/branding
  def branding
    if @company.update_branding!(branding_params)
      render json: {
        branding: @company.branding,
        message: 'Branding updated successfully'
      }
    else
      render json: {
        errors: @company.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_company
    @company = current_company || current_user&.company

    unless @company
      render json: { error: 'Company not found' }, status: :not_found
    end
  end

  def authorize_company_admin
    unless current_user&.role_admin?
      render json: { error: 'Unauthorized. Admin access required.' }, status: :forbidden
    end
  end

  def signup_params
    params.permit(
      :name,
      :subdomain,
      :business_email,
      :business_phone,
      :address,
      :timezone,
      :default_currency
    )
  end

  def update_params
    params.permit(
      :name,
      :business_email,
      :business_phone,
      :address,
      :timezone,
      :default_currency,
      settings: {}
    )
  end

  def branding_params
    params.permit(
      :logo,
      :primary_color,
      :secondary_color
    )
  end

  def company_response(company)
    {
      id: company.id,
      name: company.name,
      subdomain: company.subdomain,
      custom_domain: company.custom_domain,
      business_email: company.business_email,
      business_phone: company.business_phone,
      address: company.address,
      timezone: company.timezone,
      default_currency: company.default_currency,
      status: company.status,
      subscription_tier: company.subscription_tier,
      trial_ends_at: company.trial_ends_at,
      active: company.active,
      primary_domain: company.primary_domain,
      created_at: company.created_at
    }
  end

  def user_response(user)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role
    }
  end

  def available_features
    features = [
      :basic_bookings,
      :product_management,
      :client_management,
      :multi_location,
      :advanced_analytics,
      :api_access,
      :white_label,
      :custom_domain,
      :priority_support,
      :unlimited_users,
      :contracts,
      :recurring_bookings,
      :product_bundles
    ]

    features.map do |feature|
      {
        name: feature,
        enabled: @company.feature_enabled?(feature)
      }
    end
  end

  def generate_suggestions(subdomain)
    suggestions = []

    # Add numbers
    (1..3).each do |n|
      candidate = "#{subdomain}#{n}"
      suggestions << candidate unless Company.exists?(['LOWER(subdomain) = ?', candidate])
    end

    # Add common suffixes
    %w[app rental rentals co hq].each do |suffix|
      candidate = "#{subdomain}-#{suffix}"
      suggestions << candidate unless Company.exists?(['LOWER(subdomain) = ?', candidate])
    end

    suggestions.take(3)
  end
end
