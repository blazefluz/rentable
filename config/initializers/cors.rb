# config/initializers/cors.rb
# Configure CORS for API access

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*' # Change to your frontend domain in production, e.g., 'https://yourdomain.com'

    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization'],
      max_age: 600
  end
end
