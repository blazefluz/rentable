# DevOps Engineer

Expert deployment, infrastructure, and operations for the Rentable platform.

## Description

Handles infrastructure, deployment, monitoring, and operational excellence:
- Docker containerization
- CI/CD pipelines
- Cloud deployment (AWS/Railway/Render)
- Database management and backups
- Monitoring and logging
- Security and compliance
- Performance tuning
- Disaster recovery

## When to Use

Use this skill when you need to:
- Deploy application to production
- Set up CI/CD pipelines
- Configure monitoring and alerts
- Optimize server performance
- Handle database migrations
- Set up backups and disaster recovery
- Manage SSL certificates
- Scale infrastructure
- Debug production issues

## Commands & Examples

### Docker Setup
```dockerfile
# Dockerfile
FROM ruby:3.4.2-alpine

RUN apk add --no-cache \
  build-base \
  postgresql-dev \
  nodejs \
  npm \
  git

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package*.json ./
RUN npm install

COPY . .

RUN bundle exec rails assets:precompile

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  db:
    image: postgres:15-alpine
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: rentable_production

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

  web:
    build: .
    command: bundle exec rails server -b 0.0.0.0
    volumes:
      - .:/app
    ports:
      - "3000:3000"
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgresql://postgres:${DB_PASSWORD}@db/rentable_production
      REDIS_URL: redis://redis:6379/0
      RAILS_ENV: production

  sidekiq:
    build: .
    command: bundle exec sidekiq
    volumes:
      - .:/app
    depends_on:
      - db
      - redis
    environment:
      DATABASE_URL: postgresql://postgres:${DB_PASSWORD}@db/rentable_production
      REDIS_URL: redis://redis:6379/0

volumes:
  postgres_data:
  redis_data:
```

### GitHub Actions CI/CD
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4.2
          bundler-cache: true

      - name: Run tests
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost/test
          RAILS_ENV: test
        run: |
          bundle exec rails db:create db:migrate
          bundle exec rspec

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v3

      - name: Deploy to Railway
        uses: bervProject/railway-deploy@main
        with:
          railway_token: ${{ secrets.RAILWAY_TOKEN }}
          service: rentable-api
```

### Database Backup Script
```bash
#!/bin/bash
# scripts/backup_database.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups"
DB_NAME="rentable_production"

# Create backup
pg_dump $DB_NAME | gzip > "$BACKUP_DIR/backup_$DATE.sql.gz"

# Upload to S3
aws s3 cp "$BACKUP_DIR/backup_$DATE.sql.gz" \
  s3://rentable-backups/database/

# Keep only last 30 days locally
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +30 -delete

echo "Backup completed: backup_$DATE.sql.gz"
```

### Monitoring with New Relic
```ruby
# config/newrelic.yml
common: &default_settings
  license_key: <%= ENV['NEW_RELIC_LICENSE_KEY'] %>
  app_name: Rentable API
  distributed_tracing:
    enabled: true
  transaction_tracer:
    enabled: true
    transaction_threshold: apdex_f
  error_collector:
    enabled: true
  browser_monitoring:
    auto_instrument: true

production:
  <<: *default_settings
  monitor_mode: true

development:
  <<: *default_settings
  monitor_mode: false
```

### Health Check Endpoint
```ruby
# config/routes.rb
get '/health', to: 'health#check'

# app/controllers/health_controller.rb
class HealthController < ApplicationController
  skip_before_action :authenticate_user!

  def check
    health = {
      status: 'ok',
      timestamp: Time.current.iso8601,
      checks: {
        database: check_database,
        redis: check_redis,
        sidekiq: check_sidekiq,
        disk_space: check_disk_space,
      }
    }

    status_code = health[:checks].values.all? { |v| v[:status] == 'ok' } ? :ok : :service_unavailable

    render json: health, status: status_code
  end

  private

  def check_database
    ActiveRecord::Base.connection.execute('SELECT 1')
    { status: 'ok', latency_ms: 0 }
  rescue => e
    { status: 'error', message: e.message }
  end

  def check_redis
    Redis.new.ping
    { status: 'ok' }
  rescue => e
    { status: 'error', message: e.message }
  end

  def check_sidekiq
    stats = Sidekiq::Stats.new
    {
      status: 'ok',
      processes: stats.processes_size,
      queues: stats.queues
    }
  rescue => e
    { status: 'error', message: e.message }
  end

  def check_disk_space
    stat = Sys::Filesystem.stat('/')
    percent_used = ((stat.blocks - stat.blocks_available).to_f / stat.blocks * 100).round(2)

    {
      status: percent_used < 90 ? 'ok' : 'warning',
      percent_used: percent_used
    }
  end
end
```

### SSL Setup with Let's Encrypt
```bash
# Install certbot
sudo apt-get install certbot

# Get certificate
sudo certbot certonly --standalone -d rentable.com -d api.rentable.com

# Auto-renewal cron job
0 0 * * * certbot renew --quiet
```

### Performance Monitoring
```ruby
# config/initializers/rack_mini_profiler.rb
if Rails.env.development?
  require 'rack-mini-profiler'

  Rack::MiniProfilerRails.initialize!(Rails.application)

  Rack::MiniProfiler.config.position = 'bottom-right'
  Rack::MiniProfiler.config.start_hidden = true
end
```

## Best Practices

1. **Automate Everything**: Use CI/CD for deployments
2. **Monitor Proactively**: Set up alerts before issues occur
3. **Backup Regularly**: Automated daily backups with testing
4. **Use Infrastructure as Code**: Terraform/CloudFormation
5. **Implement Blue-Green Deployments**: Zero downtime
6. **Log Centralization**: Use ELK stack or CloudWatch
7. **Security First**: Regular updates, vulnerability scanning
8. **Document Runbooks**: For common operational tasks

## Related Skills
- backend-developer
- database-administrator
- security-engineer
- technical-architect
