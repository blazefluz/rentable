class TenantMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = ActionDispatch::Request.new(env)
    
    # Extract subdomain from host
    subdomain = extract_subdomain(request.host)
    
    # Set current tenant
    if subdomain.present? && subdomain != 'www'
      instance = Instance.find_by(subdomain: subdomain, active: true)
      Current.instance = instance
    else
      # Use default instance or allow access without tenant
      Current.instance = Instance.find_by(subdomain: 'default') || Instance.first
    end
    
    @app.call(env)
  ensure
    # Clear current tenant after request
    Current.instance = nil
  end

  private

  def extract_subdomain(host)
    # Remove port if present
    host = host.split(':').first
    
    # Split by dots
    parts = host.split('.')
    
    # If we have at least 3 parts (subdomain.domain.tld), return subdomain
    # Skip 'www' as it's not a tenant subdomain
    return nil if parts.length < 3
    return nil if parts.first == 'www'
    
    parts.first
  end
end
