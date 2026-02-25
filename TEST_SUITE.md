# Test Suite Documentation

## Overview

The application now has a comprehensive RSpec test suite with **90 test cases** covering models, controllers, and API endpoints.

## Test Coverage

### Models (4 model specs)
- **Product** - 17 tests
- **Booking** - 15 tests
- **Kit** - 13 tests
- **User** - 11 tests

### API Endpoints (4 request specs)
- **Products API** - 11 tests
- **Bookings API** - 10 tests
- **Kits API** - 8 tests
- **Authentication API** - 7 tests

## Test Infrastructure

### Testing Gems Installed
- **rspec-rails** (7.1) - Testing framework
- **factory_bot_rails** (6.4) - Test data factories
- **faker** (3.5) - Fake data generation
- **shoulda-matchers** (6.4) - Model validation matchers
- **database_cleaner-active_record** (2.2) - Database cleaning
- **simplecov** - Code coverage reporting
- **webmock** (3.24) - HTTP request stubbing
- **vcr** (6.3) - Record HTTP interactions

### Factories Created
Located in `spec/factories/`:
- products.rb
- bookings.rb
- booking_line_items.rb
- kits.rb
- kit_items.rb
- clients.rb
- locations.rb
- users.rb

### Configuration Files
- **spec/spec_helper.rb** - RSpec configuration
- **spec/rails_helper.rb** - Rails-specific configuration with:
  - FactoryBot integration
  - DatabaseCleaner setup
  - Shoulda Matchers configuration
  - Automatic spec type inference

## Running Tests

### Run All Tests
```bash
bundle exec rspec
```

### Run Specific Test File
```bash
bundle exec rspec spec/models/product_spec.rb
```

### Run with Documentation Format
```bash
bundle exec rspec --format documentation
```

### Run with Coverage Report
```bash
COVERAGE=true bundle exec rspec
```

### Run Tests for Specific Line
```bash
bundle exec rspec spec/models/product_spec.rb:35
```

## Test Results Summary

**Current Status:**
- Total Examples: 90
- Passing: 50
- Failing: 40

### Common Failure Patterns

Most failures are due to:
1. Missing model methods (e.g., `duration_days`, `generate_api_token`)
2. Missing controller actions (e.g., auth endpoints)
3. Association naming mismatches (e.g., `location` vs `storage_location`)
4. Missing validations or enum definitions

These failures are expected for a new test suite and help identify:
- Missing features to implement
- API endpoints that need creation
- Model methods that need to be added

## Test Organization

```
spec/
├── factories/           # FactoryBot factories for test data
│   ├── bookings.rb
│   ├── booking_line_items.rb
│   ├── clients.rb
│   ├── kit_items.rb
│   ├── kits.rb
│   ├── locations.rb
│   ├── products.rb
│   └── users.rb
├── models/              # Model unit tests
│   ├── booking_spec.rb
│   ├── kit_spec.rb
│   ├── product_spec.rb
│   └── user_spec.rb
├── requests/            # API integration tests
│   └── api/
│       └── v1/
│           ├── auth_spec.rb
│           ├── bookings_spec.rb
│           ├── kits_spec.rb
│           └── products_spec.rb
├── support/             # Support files
│   └── factory_bot.rb
├── rails_helper.rb      # Rails test configuration
├── spec_helper.rb       # RSpec configuration
└── swagger_helper.rb    # Swagger/OpenAPI configuration
```

## Writing New Tests

### Model Test Example
```ruby
require 'rails_helper'

RSpec.describe Product, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe '#custom_method' do
    let(:product) { create(:product) }

    it 'performs expected behavior' do
      expect(product.custom_method).to eq(expected_value)
    end
  end
end
```

### Request Test Example
```ruby
require 'rails_helper'

RSpec.describe 'Api::V1::Products', type: :request do
  describe 'GET /api/v1/products' do
    it 'returns all products' do
      create_list(:product, 3)
      get '/api/v1/products'

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['products'].length).to eq(3)
    end
  end
end
```

## Best Practices

1. **Use Factories** - Use FactoryBot instead of manual creation
2. **Let Blocks** - Define test data with `let` or `let!`
3. **One Assertion Per Test** - Keep tests focused
4. **Descriptive Names** - Use clear test descriptions
5. **Arrange-Act-Assert** - Follow the AAA pattern
6. **Avoid Time-Dependent Tests** - Use Timecop or relative dates
7. **Clean Database** - DatabaseCleaner handles this automatically

## Continuous Integration

To integrate with CI/CD:

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:14
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v2
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4
          bundler-cache: true
      - run: bundle exec rails db:create db:migrate
        env:
          RAILS_ENV: test
      - run: bundle exec rspec
```

## Next Steps

To improve test coverage:
1. Fix failing tests by implementing missing features
2. Add tests for remaining controllers
3. Add integration tests for complex workflows
4. Add system/feature tests for critical user flows
5. Set up code coverage reporting (SimpleCov)
6. Configure CI/CD pipeline

## Useful Commands

```bash
# Run tests matching a pattern
bundle exec rspec --pattern 'spec/models/**/*_spec.rb'

# Run only failed tests from last run
bundle exec rspec --only-failures

# Run tests in random order
bundle exec rspec --order random

# Profile slowest tests
bundle exec rspec --profile 10

# Generate spec files for models
bin/rails generate rspec:model Product

# Generate spec files for controllers
bin/rails generate rspec:controller Api::V1::Products
```

## Resources

- [RSpec Documentation](https://rspec.info/)
- [FactoryBot Documentation](https://github.com/thoughtbot/factory_bot)
- [Shoulda Matchers](https://github.com/thoughtbot/shoulda-matchers)
- [Better Specs](https://www.betterspecs.org/)
