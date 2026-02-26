module SetCurrentTenant
  extend ActiveSupport::Concern

  included do
    before_action :set_current_tenant
    before_action :verify_tenant_access
  end

  private

  def set_current_tenant
    # Get company from request (subdomain or custom domain)
    company = find_company_from_request

    if company
      ActsAsTenant.current_tenant = company
      @current_company = company
    elsif require_tenant?
      render_tenant_not_found
    end
  end

  def find_company_from_request
    host = request.host

    # Remove port if present
    host = host.split(':').first

    # Skip for certain controllers/actions
    return nil if skip_tenant_resolution?

    # Try custom domain first
    company = Company.active.find_by('LOWER(custom_domain) = ?', host.downcase)
    return company if company

    # Try subdomain
    subdomain = extract_subdomain(host)
    if subdomain.present?
      company = Company.active.find_by('LOWER(subdomain) = ?', subdomain.downcase)
      return company if company
    end

    # In development/test, use first company or user's company
    if Rails.env.development? || Rails.env.test?
      return current_user&.company || Company.first
    end

    nil
  end

  def extract_subdomain(host)
    base_domain = Rails.application.config.base_domain || 'localhost'

    return nil if host == base_domain
    return nil unless host.end_with?(".#{base_domain}")

    host.gsub(".#{base_domain}", '').split('.').last
  end

  def skip_tenant_resolution?
    # Controllers that don't need tenant resolution
    controller_name == 'companies' && action_name.in?(%w[signup create check_subdomain])
  end

  def require_tenant?
    # Most controllers require a tenant
    true
  end

  def verify_tenant_access
    return unless @current_company

    # Verify user belongs to this company
    if current_user && current_user.company_id != @current_company.id
      render json: { error: 'Unauthorized access to this company' }, status: :forbidden
    end

    # Verify company is active
    unless @current_company.active?
      render_company_inactive
    end
  end

  def render_tenant_not_found
    render json: { error: 'Company not found' }, status: :not_found
  end

  def render_company_inactive
    status_message = case @current_company.status
    when 'suspended'
      'Your account has been suspended. Please contact support.'
    when 'cancelled'
      'Your subscription has been cancelled.'
    when 'expired'
      'Your trial has expired. Please upgrade to continue.'
    else
      'Your account is not active.'
    end

    render json: { error: status_message }, status: :forbidden
  end

  def current_company
    @current_company ||= ActsAsTenant.current_tenant
  end

  helper_method :current_company
end
