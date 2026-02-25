# Deployment Guide

## Environment Setup

This application supports four environments:
- **Development** - Local development environment
- **Test** - Automated testing environment
- **SIT (System Integration Testing)** - Integration testing environment
- **UAT (User Acceptance Testing)** - User acceptance testing environment
- **Production** - Production environment

## SIT Environment Setup

### 1. Database Setup

```bash
# Create the SIT database
RAILS_ENV=sit bin/rails db:create

# Run migrations
RAILS_ENV=sit bin/rails db:migrate

# Seed initial data (optional)
RAILS_ENV=sit bin/rails db:seed
```

### 2. Environment Configuration

Create a `.env.sit` file based on `.env.sit.example`:

```bash
cp .env.sit.example .env.sit
```

Edit `.env.sit` and configure:
- Database credentials
- SMTP settings for email delivery
- Secret key base (generate with `rails secret`)
- Stripe test API keys
- CORS origins if needed

### 3. Running the SIT Server

```bash
# Start the server
RAILS_ENV=sit bin/rails server -p 3001

# Or with specific binding
RAILS_ENV=sit bin/rails server -p 3001 -b 0.0.0.0
```

### 4. Testing SIT Environment

```bash
# Check server health
curl http://localhost:3001/up

# Test API endpoints
curl http://localhost:3001/api/v1/products
```

## UAT Environment Setup

### 1. Database Setup

```bash
# Create the UAT database
RAILS_ENV=uat bin/rails db:create

# Run migrations
RAILS_ENV=uat bin/rails db:migrate

# Seed initial data (optional)
RAILS_ENV=uat bin/rails db:seed
```

### 2. Environment Configuration

Create a `.env.uat` file based on `.env.uat.example`:

```bash
cp .env.uat.example .env.uat
```

Edit `.env.uat` and configure:
- Database credentials
- SMTP settings for email delivery
- Secret key base (generate with `rails secret`)
- Stripe test API keys
- CORS origins (frontend URL)

### 3. Running the UAT Server

```bash
# Start the server
RAILS_ENV=uat bin/rails server -p 3002

# Or with specific binding
RAILS_ENV=uat bin/rails server -p 3002 -b 0.0.0.0
```

### 4. Testing UAT Environment

```bash
# Check server health
curl http://localhost:3002/up

# Test API endpoints
curl http://localhost:3002/api/v1/products
```

## Production Deployment

### 1. Prerequisites

- PostgreSQL database configured
- Ruby 3.x installed
- Node.js for asset compilation
- Environment variables configured

### 2. Database Setup

```bash
# Create and migrate database
RAILS_ENV=production bin/rails db:create db:migrate

# Seed initial data if needed
RAILS_ENV=production bin/rails db:seed
```

### 3. Asset Precompilation

```bash
RAILS_ENV=production bin/rails assets:precompile
```

### 4. Environment Variables

Ensure all required environment variables are set:
- `SECRET_KEY_BASE`
- `RENTABLE_DATABASE_PASSWORD`
- `SMTP_*` variables for email
- `STRIPE_*` variables for payments
- `DB_HOST`, `DB_USER`, etc.

### 5. Running in Production

```bash
# Using Rails server (not recommended for production)
RAILS_ENV=production bin/rails server

# Using Puma (recommended)
RAILS_ENV=production bundle exec puma -C config/puma.rb
```

## Database Management

### Creating Databases for All Environments

```bash
# Create all databases at once
bin/rails db:create:all

# Or individually
RAILS_ENV=sit bin/rails db:create
RAILS_ENV=uat bin/rails db:create
RAILS_ENV=production bin/rails db:create
```

### Running Migrations

```bash
# Run for specific environment
RAILS_ENV=sit bin/rails db:migrate
RAILS_ENV=uat bin/rails db:migrate

# Rollback if needed
RAILS_ENV=sit bin/rails db:rollback
RAILS_ENV=uat bin/rails db:rollback
```

### Database Seeding

```bash
# Seed with sample data
RAILS_ENV=sit bin/rails db:seed
RAILS_ENV=uat bin/rails db:seed
```

## Environment Differences

### Development
- Hot reloading enabled
- Verbose logging
- Email preview in browser (letter_opener)
- Less strict security settings

### SIT
- Production-like configuration
- Integrated testing focus
- Detailed logging
- Permissive CORS for testing

### UAT
- Production-like configuration
- End-user testing focus
- Configurable CORS
- Similar to production settings

### Production
- Optimized for performance
- Strict security settings
- Minimal logging
- Asset caching enabled

## Troubleshooting

### Database Connection Issues

```bash
# Check PostgreSQL is running
pg_isready

# Check database exists
RAILS_ENV=sit bin/rails db:version
```

### Missing Environment Variables

```bash
# Check current environment
echo $RAILS_ENV

# Verify .env file is loaded
cat .env.sit
```

### Port Already in Use

```bash
# Find process using port
lsof -i :3001

# Kill the process
kill -9 <PID>
```

## Deployment Checklist

- [ ] Environment configuration files created
- [ ] Database credentials configured
- [ ] Secret key base generated
- [ ] Database created and migrated
- [ ] SMTP settings configured
- [ ] Stripe API keys configured
- [ ] CORS origins configured
- [ ] Server starts successfully
- [ ] API endpoints respond correctly
- [ ] Email delivery tested
- [ ] File uploads tested
- [ ] Background jobs working

## Security Notes

- Never commit `.env.*` files (only commit `.example` versions)
- Use strong passwords for database credentials
- Rotate secret keys regularly
- Use HTTPS in UAT and production
- Keep dependencies updated
- Review CORS settings for production
- Use Stripe test keys in non-production environments
