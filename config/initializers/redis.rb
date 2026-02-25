# Redis configuration for caching
if Rails.env.production? || Rails.env.uat? || Rails.env.sit?
  REDIS_CLIENT = Redis.new(
    url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
    timeout: 5,
    reconnect_attempts: 3
  )
else
  # Use Rails.cache in development/test (memory store)
  REDIS_CLIENT = nil
end
