# config/initializers/cors.rb
# Configure CORS for API access

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Allow requests from your frontend domain
    # IMPORTANT: Cannot use '*' wildcard when credentials are included
    origins 'http://localhost:3000',
            'http://localhost:3001',
            'http://localhost:5173',  # Vite default
            'http://127.0.0.1:3000',
            /\Ahttp:\/\/localhost:\d+\z/,  # Any localhost port
            /\Ahttp:\/\/127\.0\.0\.1:\d+\z/  # Any 127.0.0.1 port

    resource '/api/*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true,  # Allow credentials (cookies, authorization headers)
      expose: ['Authorization', 'Content-Type'],
      max_age: 600
  end

  # In production, replace with your actual domain(s):
  # allow do
  #   origins 'https://yourdomain.com', 'https://app.yourdomain.com'
  #
  #   resource '/api/*',
  #     headers: :any,
  #     methods: [:get, :post, :put, :patch, :delete, :options, :head],
  #     credentials: true,
  #     expose: ['Authorization', 'Content-Type'],
  #     max_age: 600
  # end
end
