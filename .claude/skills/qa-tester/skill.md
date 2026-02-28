# QA Tester & Quality Assurance

Comprehensive testing and quality assurance for the Rentable platform.

## Description

Ensures software quality through systematic testing:
- Manual and automated testing
- Test case design and execution
- Bug reporting and tracking
- API testing
- Performance testing
- Security testing
- Regression testing
- User acceptance testing (UAT)

## When to Use

Use this skill when you need to:
- Write test cases and test plans
- Perform manual testing
- Create automated tests
- Test API endpoints
- Verify bug fixes
- Perform regression testing
- Validate user stories
- Test edge cases
- Load and stress testing

## Testing Types

### 1. Unit Testing (RSpec)
```ruby
# spec/models/booking_spec.rb
require 'rails_helper'

RSpec.describe Booking, type: :model do
  describe 'validations' do
    it 'requires start_date' do
      booking = Booking.new(start_date: nil)
      expect(booking).not_to be_valid
      expect(booking.errors[:start_date]).to include("can't be blank")
    end

    it 'requires end_date after start_date' do
      booking = Booking.new(
        start_date: Date.today,
        end_date: Date.yesterday
      )
      expect(booking).not_to be_valid
      expect(booking.errors[:end_date]).to include("must be after the start date")
    end
  end

  describe '#total_days' do
    it 'calculates total days correctly' do
      booking = Booking.new(
        start_date: Date.parse('2026-03-01'),
        end_date: Date.parse('2026-03-05')
      )
      expect(booking.total_days).to eq(5)
    end
  end

  describe '#available?' do
    let(:product) { create(:product, quantity: 5) }

    it 'returns true when items are available' do
      booking = create(:booking)
      booking.booking_line_items.create!(
        bookable: product,
        quantity: 3
      )

      expect(booking.available?).to be true
    end

    it 'returns false when items are not available' do
      # Create existing booking using all inventory
      existing = create(:booking, :confirmed)
      existing.booking_line_items.create!(
        bookable: product,
        quantity: 5
      )

      # Try to book same product
      new_booking = build(:booking)
      new_booking.booking_line_items.build(
        bookable: product,
        quantity: 1
      )

      expect(new_booking.available?).to be false
    end
  end
end
```

### 2. Request/Integration Testing
```ruby
# spec/requests/api/v1/bookings_spec.rb
require 'rails_helper'

RSpec.describe 'Api::V1::Bookings', type: :request do
  let(:company) { create(:company) }
  let(:user) { create(:user, :admin, company: company) }
  let(:headers) { { 'Authorization' => "Bearer #{user.generate_jwt}" } }

  before { ActsAsTenant.current_tenant = company }

  describe 'POST /api/v1/bookings' do
    let(:product) { create(:product, company: company, quantity: 5) }
    let(:valid_params) do
      {
        booking: {
          customer_name: 'John Doe',
          customer_email: 'john@example.com',
          start_date: 3.days.from_now.to_s,
          end_date: 5.days.from_now.to_s,
          booking_line_items_attributes: [
            {
              bookable_type: 'Product',
              bookable_id: product.id,
              quantity: 2,
              days: 2
            }
          ]
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new booking' do
        expect {
          post '/api/v1/bookings', params: valid_params, headers: headers
        }.to change(Booking, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)['booking']).to include(
          'customer_name' => 'John Doe',
          'status' => 'draft'
        )
      end

      it 'creates booking line items' do
        post '/api/v1/bookings', params: valid_params, headers: headers

        booking = Booking.last
        expect(booking.booking_line_items.count).to eq(1)
        expect(booking.booking_line_items.first.quantity).to eq(2)
      end
    end

    context 'with invalid parameters' do
      it 'returns validation errors' do
        invalid_params = valid_params.deep_dup
        invalid_params[:booking][:customer_name] = ''

        post '/api/v1/bookings', params: invalid_params, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to be_present
      end
    end

    context 'when items are not available' do
      before do
        # Book all inventory
        existing = create(:booking, :confirmed, company: company)
        existing.booking_line_items.create!(
          bookable: product,
          quantity: 5
        )
      end

      it 'returns availability error' do
        post '/api/v1/bookings', params: valid_params, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['errors']).to include(
          match(/not available/)
        )
      end
    end
  end
end
```

### 3. API Testing with Postman/Newman
```json
{
  "info": {
    "name": "Rentable API Tests",
    "_postman_id": "12345",
    "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
  },
  "item": [
    {
      "name": "Authentication",
      "item": [
        {
          "name": "Login",
          "event": [
            {
              "listen": "test",
              "script": {
                "exec": [
                  "pm.test(\"Status code is 200\", function () {",
                  "    pm.response.to.have.status(200);",
                  "});",
                  "",
                  "pm.test(\"Response has token\", function () {",
                  "    var jsonData = pm.response.json();",
                  "    pm.expect(jsonData).to.have.property('token');",
                  "    pm.environment.set(\"token\", jsonData.token);",
                  "});"
                ]
              }
            }
          ],
          "request": {
            "method": "POST",
            "header": [],
            "body": {
              "mode": "raw",
              "raw": "{\n  \"email\": \"admin@test.com\",\n  \"password\": \"password123\"\n}"
            },
            "url": "{{base_url}}/api/v1/auth/login"
          }
        }
      ]
    }
  ]
}
```

### 4. Load Testing with k6
```javascript
// load_tests/booking_api.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '1m', target: 10 },  // Ramp up to 10 users
    { duration: '3m', target: 10 },  // Stay at 10 users
    { duration: '1m', target: 50 },  // Ramp up to 50 users
    { duration: '3m', target: 50 },  // Stay at 50 users
    { duration: '1m', target: 0 },   // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests must complete below 500ms
    http_req_failed: ['rate<0.01'],   // Error rate must be below 1%
  },
};

const BASE_URL = 'http://localhost:4000/api/v1';
const TOKEN = 'YOUR_JWT_TOKEN';

export default function () {
  // Test: List products
  let response = http.get(`${BASE_URL}/products`, {
    headers: { Authorization: `Bearer ${TOKEN}` },
  });

  check(response, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'has products array': (r) => JSON.parse(r.body).products !== undefined,
  });

  sleep(1);

  // Test: Get single product
  response = http.get(`${BASE_URL}/products/44`, {
    headers: { Authorization: `Bearer ${TOKEN}` },
  });

  check(response, {
    'product fetch status is 200': (r) => r.status === 200,
    'has product object': (r) => JSON.parse(r.body).product !== undefined,
  });

  sleep(1);
}
```

### 5. E2E Testing with Cypress
```javascript
// cypress/e2e/booking_flow.cy.js
describe('Booking Flow', () => {
  beforeEach(() => {
    cy.login('admin@test.com', 'password123');
  });

  it('creates a new booking successfully', () => {
    // Navigate to products
    cy.visit('/products');

    // Select a product
    cy.contains('Canon EOS R5').click();

    // Add to cart
    cy.get('[data-testid="add-to-cart"]').click();

    // Go to booking
    cy.get('[data-testid="create-booking"]').click();

    // Fill in customer details
    cy.get('[data-testid="customer-name"]').type('John Doe');
    cy.get('[data-testid="customer-email"]').type('john@example.com');
    cy.get('[data-testid="customer-phone"]').type('+1 555-0100');

    // Select dates
    cy.get('[data-testid="start-date"]').type('2026-03-15');
    cy.get('[data-testid="end-date"]').type('2026-03-17');

    // Submit
    cy.get('[data-testid="create-booking-btn"]').click();

    // Verify success
    cy.contains('Booking created successfully').should('be.visible');
    cy.url().should('include', '/bookings/');
  });

  it('shows error when dates overlap', () => {
    // Create existing booking first
    cy.createBooking({
      product_id: 44,
      start_date: '2026-03-15',
      end_date: '2026-03-17',
    });

    // Try to create overlapping booking
    cy.visit('/products/44');
    cy.get('[data-testid="add-to-cart"]').click();
    cy.get('[data-testid="create-booking"]').click();

    cy.get('[data-testid="start-date"]').type('2026-03-16');
    cy.get('[data-testid="end-date"]').type('2026-03-18');
    cy.get('[data-testid="create-booking-btn"]').click();

    // Verify error
    cy.contains('not available').should('be.visible');
  });
});
```

## Test Case Template

```markdown
### Test Case: TC-001 - Create New Booking

**Priority**: High
**Type**: Functional
**Module**: Bookings

**Preconditions**:
- User is logged in with admin role
- At least 1 product exists with quantity > 0
- Product is active and bookable

**Test Steps**:
1. Navigate to Products page
2. Click on a product
3. Click "Create Booking" button
4. Fill in customer name: "John Doe"
5. Fill in customer email: "john@example.com"
6. Select start date: 3 days from today
7. Select end date: 5 days from today
8. Select quantity: 1
9. Click "Create Booking" button

**Expected Results**:
- Booking is created successfully
- Redirect to booking detail page
- Success message is displayed
- Booking reference number is generated
- Booking status is "draft"
- Line items are created correctly

**Actual Results**:
[To be filled during test execution]

**Status**:
[Pass/Fail/Blocked]

**Notes**:
[Any observations]
```

## Bug Report Template

```markdown
### Bug Report: BUG-001

**Title**: Booking total calculation incorrect when using weekend pricing

**Severity**: High
**Priority**: P1
**Status**: Open
**Reported By**: QA Tester
**Assigned To**: Backend Developer
**Environment**: Production

**Description**:
When creating a booking that spans weekend days, the total price calculation
does not correctly apply the weekend pricing rate.

**Steps to Reproduce**:
1. Login as admin
2. Create product with daily_price: $100, weekend_price: $150
3. Create booking from Saturday to Monday (3 days)
4. Observe calculated total

**Expected Result**:
Total should be: (2 weekend days × $150) + (1 weekday × $100) = $400

**Actual Result**:
Total shows: 3 days × $100 = $300

**Screenshots**:
[Attach screenshots]

**Logs**:
```
[2026-02-28 10:15:33] Booking#calculate_total_price
price_cents: 10000
quantity: 1
days: 3
total: 30000
```

**Additional Information**:
- Browser: Chrome 121
- User role: Admin
- Company: Acme Rentals (ID: 1)
```

## Testing Checklist

### Pre-Release Testing
- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] API endpoints tested
- [ ] Multi-tenancy verified
- [ ] Payment flow tested
- [ ] Email notifications working
- [ ] Data validation working
- [ ] Security testing completed
- [ ] Performance testing done
- [ ] Cross-browser testing
- [ ] Mobile responsiveness
- [ ] Accessibility audit

### Regression Testing
- [ ] Login/logout functionality
- [ ] Product CRUD operations
- [ ] Booking creation workflow
- [ ] Payment processing
- [ ] Availability checking
- [ ] Email notifications
- [ ] Report generation
- [ ] Export functionality
- [ ] Search and filtering
- [ ] Pagination

## Related Skills
- backend-developer
- frontend-developer
- devops-engineer
- security-engineer
