class TenantMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    # Determine company from subdomain or custom domain
    company = find_company(request)

    # Set the current tenant
    ActsAsTenant.with_tenant(company) do
      @app.call(env)
    end
  rescue ActiveRecord::RecordNotFound
    # Company not found - return 404 or redirect to signup
    [404, { 'Content-Type' => 'text/html' }, ['Company not found']]
  end

  private

  def find_company(request)
    host = request.host

    # Remove port if present
    host = host.split(':').first

    # Skip tenant resolution for certain paths (public signup, health checks, etc.)
    return nil if skip_tenant_resolution?(request.path)

    # Try to find by custom domain first
    company = Company.find_by('LOWER(custom_domain) = ?', host.downcase)
    return company if company

    # Try to find by subdomain
    subdomain = extract_subdomain(host)
    if subdomain.present?
      company = Company.find_by('LOWER(subdomain) = ?', subdomain.downcase)
      return company if company
    end

    # In development/test, allow no subdomain and use first company
    if Rails.env.development? || Rails.env.test?
      return Company.first if Company.exists?
    end

    # No company found
    nil
  end

  def extract_subdomain(host)
    # Remove base domain to get subdomain
    # Example: acme.rentable.com -> acme
    base_domain = Rails.application.config.base_domain || 'localhost'

    return nil if host == base_domain
    return nil if host.end_with?(".#{base_domain}") == false

    host.gsub(".#{base_domain}", '').split('.').last
  end

  def skip_tenant_resolution?(path)
    # Skip for public paths
    public_paths = [
      '/health',
      '/signup',
      '/api/v1/companies/signup',
      '/api/v1/companies/check_subdomain'
    ]

    public_paths.any? { |public_path| path.start_with?(public_path) }
  end
end
