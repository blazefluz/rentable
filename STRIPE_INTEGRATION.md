# Stripe Payment Integration - Complete Guide

## Overview

Complete Stripe integration for **API-only** rental management system. Supports full payments, partial payments (deposits), refunds, and dispute handling.

---

## Setup

### 1. Environment Variables

Add to `.env` or environment configuration:

```bash
STRIPE_SECRET_KEY=sk_test_...         # Get from Stripe Dashboard
STRIPE_PUBLISHABLE_KEY=pk_test_...    # For client-side (mobile app/frontend)
STRIPE_WEBHOOK_SECRET=whsec_...       # Get from Stripe Webhook settings
```

### 2. Install Stripe Gem

```bash
# Already installed
bundle add stripe
```

### 3. Configure Webhook in Stripe Dashboard

1. Go to: https://dashboard.stripe.com/webhooks
2. Add endpoint: `https://yourdomain.com/api/v1/payments/stripe/webhook`
3. Select events to listen for:
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`
   - `payment_intent.canceled`
   - `charge.refunded`
   - `charge.dispute.created`
   - `charge.dispute.closed`
4. Copy the **Webhook Signing Secret** → `STRIPE_WEBHOOK_SECRET`

---

## API Endpoints

### 1. Create Payment Intent

**Endpoint:** `POST /api/v1/payments/stripe/create_intent`

Creates a Stripe Payment Intent for a booking. Supports full payment, deposits, or balance payment.

**Request Body:**
```json
{
  "booking_id": 123,
  "amount_cents": 50000,          // Optional: specific amount
  "deposit_percent": 30           // Optional: percentage deposit (30%)
  // If neither provided, charges full balance_due
}
```

**Response:**
```json
{
  "client_secret": "pi_3ABC123_secret_xyz",
  "payment_intent_id": "pi_3ABC123",
  "amount": 50000,
  "currency": "usd",
  "status": "requires_payment_method",
  "customer_id": "cus_ABC123",
  "booking": {
    "id": 123,
    "reference": "BK2026022509D715EE",
    "total": 150000,
    "balance_due": 150000
  }
}
```

**Use `client_secret` on client-side to complete payment with Stripe.js or mobile SDKs.**

---

### 2. Confirm Payment (Manual)

**Endpoint:** `POST /api/v1/payments/stripe/confirm_payment`

Manually confirm a payment intent (if required).

**Request Body:**
```json
{
  "payment_intent_id": "pi_3ABC123"
}
```

**Response:**
```json
{
  "payment_intent_id": "pi_3ABC123",
  "status": "succeeded",
  "amount": 50000,
  "currency": "usd"
}
```

---

### 3. Check Payment Status

**Endpoint:** `GET /api/v1/payments/stripe/payment_status/:payment_intent_id`

Check the current status of a payment.

**Response:**
```json
{
  "payment_intent_id": "pi_3ABC123",
  "status": "succeeded",
  "amount": 50000,
  "currency": "usd",
  "created": "2026-02-25T10:30:00Z",
  "metadata": {
    "booking_id": "123",
    "booking_reference": "BK2026022509D715EE"
  }
}
```

**Payment Statuses:**
- `requires_payment_method` - Waiting for customer to add payment
- `requires_confirmation` - Payment method added, needs confirmation
- `requires_action` - Customer action required (3D Secure, etc.)
- `processing` - Payment is processing
- `succeeded` - ✅ Payment successful
- `canceled` - Payment canceled
- `requires_capture` - (Not used in automatic capture mode)

---

### 4. Refund Payment

**Endpoint:** `POST /api/v1/payments/stripe/refund`

Refund a payment (full or partial).

**Request Body:**
```json
{
  "payment_intent_id": "pi_3ABC123",
  "amount_cents": 25000,                    // Optional: partial refund
  "reason": "requested_by_customer"         // or "duplicate", "fraudulent"
}
```

**Response:**
```json
{
  "refund_id": "re_3XYZ789",
  "amount": 25000,
  "currency": "usd",
  "status": "succeeded",
  "reason": "requested_by_customer"
}
```

**Note:** Refund is automatically recorded as a negative payment in the database.

---

### 5. Webhook Handler

**Endpoint:** `POST /api/v1/payments/stripe/webhook`

**⚠️ This endpoint is called by Stripe, not by your application.**

Automatically handles:
- ✅ Payment succeeded → Creates payment record, sends confirmation email
- ❌ Payment failed → Logs failure, adds note to booking
- 🚫 Payment canceled → Updates booking
- 💰 Refund processed → Confirms refund
- ⚠️ Dispute created → Alerts admin
- ✅ Dispute won/lost → Updates booking

**Webhook is secured with signature verification using `STRIPE_WEBHOOK_SECRET`.**

---

## Client-Side Integration

### Mobile App (React Native / Flutter / iOS / Android)

**1. Get Payment Intent:**
```javascript
const response = await fetch('https://api.rentable.com/api/v1/payments/stripe/create_intent', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${authToken}`
  },
  body: JSON.stringify({
    booking_id: 123,
    deposit_percent: 30  // 30% deposit
  })
});

const { client_secret, payment_intent_id } = await response.json();
```

**2. Present Payment Sheet:**

**React Native (Stripe React Native SDK):**
```javascript
import { useStripe } from '@stripe/stripe-react-native';

const { initPaymentSheet, presentPaymentSheet } = useStripe();

// Initialize
await initPaymentSheet({
  paymentIntentClientSecret: client_secret,
  merchantDisplayName: 'Rentable',
  returnURL: 'rentable://payment-complete',
});

// Present
const { error } = await presentPaymentSheet();

if (error) {
  // Handle error
} else {
  // Payment successful!
  // Webhook will automatically update booking
}
```

**iOS (Native):**
```swift
import StripePaymentSheet

let paymentSheet = PaymentSheet(paymentIntentClientSecret: clientSecret)
paymentSheet.present(from: self) { result in
  switch result {
  case .completed:
    // Payment successful
  case .canceled:
    // User canceled
  case .failed(let error):
    // Handle error
  }
}
```

**Flutter:**
```dart
import 'package:flutter_stripe/flutter_stripe.dart';

await Stripe.instance.initPaymentSheet(
  paymentSheetParameters: SetupPaymentSheetParameters(
    paymentIntentClientSecret: clientSecret,
    merchantDisplayName: 'Rentable',
  ),
);

await Stripe.instance.presentPaymentSheet();
```

---

## Payment Flow

### 1. Full Payment
```
1. Client: POST /payments/stripe/create_intent { booking_id: 123 }
2. Server: Returns client_secret
3. Client: Present Stripe payment UI with client_secret
4. Customer: Enters card details
5. Stripe: Processes payment
6. Stripe: Calls webhook → payment_intent.succeeded
7. Server: Creates Payment record, sends email
8. Server: Updates booking status to confirmed if fully paid
```

### 2. Deposit Payment (30%)
```
1. Client: POST /payments/stripe/create_intent {
     booking_id: 123,
     deposit_percent: 30
   }
2. Follow steps 2-8 above
3. Later: Client can create another intent for remaining balance
```

### 3. Refund
```
1. Admin: POST /payments/stripe/refund {
     payment_intent_id: "pi_123",
     amount_cents: 25000
   }
2. Server: Creates refund in Stripe
3. Server: Records negative payment in database
4. Stripe: Calls webhook → charge.refunded
5. Server: Confirms refund processed
```

---

## Testing

### Test Mode Cards

Use these in Stripe test mode:

**Success:**
- Card: `4242 4242 4242 4242`
- Expiry: Any future date
- CVC: Any 3 digits
- ZIP: Any 5 digits

**Requires Authentication (3D Secure):**
- Card: `4000 0027 6000 3184`

**Declined:**
- Card: `4000 0000 0000 0002`

**Insufficient Funds:**
- Card: `4000 0000 0000 9995`

### Test Webhooks Locally

**1. Install Stripe CLI:**
```bash
brew install stripe/stripe-cli/stripe
stripe login
```

**2. Forward webhooks to local server:**
```bash
stripe listen --forward-to localhost:3000/api/v1/payments/stripe/webhook
```

**3. Trigger test events:**
```bash
# Test successful payment
stripe trigger payment_intent.succeeded

# Test failed payment
stripe trigger payment_intent.payment_failed

# Test refund
stripe trigger charge.refunded
```

---

## Database Schema

### Payment Record (Created by Webhook)

When payment succeeds, a Payment record is created:

```ruby
Payment.create!(
  booking_id: 123,
  payment_type: :payment_received,
  amount_cents: 50000,
  amount_currency: "USD",
  payment_method: "Stripe",
  reference: "pi_3ABC123",        # Stripe Payment Intent ID
  payment_date: Time.current,
  comment: "Stripe payment succeeded"
)
```

### Refund Record

When refund is processed, a negative payment is created:

```ruby
Payment.create!(
  booking_id: 123,
  payment_type: :payment_received,
  amount_cents: -25000,           # Negative amount
  amount_currency: "USD",
  payment_method: "Stripe Refund",
  reference: "re_3XYZ789",        # Stripe Refund ID
  payment_date: Time.current,
  comment: "Refund: requested_by_customer"
)
```

---

## Security

### 1. Webhook Signature Verification
All webhooks are verified using `STRIPE_WEBHOOK_SECRET` to prevent fake requests.

### 2. API Authentication
Create intent endpoint requires authentication (handled by your auth system).

### 3. PCI Compliance
Payment card data **never touches your server**. Stripe handles all PCI compliance.

### 4. HTTPS Required
Stripe requires HTTPS in production. Use SSL certificate.

---

## Error Handling

### Common Errors

**1. Invalid API Key:**
```json
{
  "error": "Invalid API Key provided"
}
```
→ Check `STRIPE_SECRET_KEY` environment variable

**2. Amount Too Small:**
```json
{
  "error": "Amount must be at least $0.50 usd"
}
```
→ Minimum is 50 cents ($0.50)

**3. Currency Not Supported:**
```json
{
  "error": "Invalid currency: xyz"
}
```
→ Use supported currencies (usd, eur, gbp, etc.)

**4. Payment Failed:**
```json
{
  "error": "Your card was declined"
}
```
→ Customer should try different payment method

---

## Production Checklist

### Before Going Live:

- [ ] Replace test API keys with **live keys**
- [ ] Configure **live webhook** endpoint in Stripe Dashboard
- [ ] Update `STRIPE_WEBHOOK_SECRET` with live webhook secret
- [ ] Enable **HTTPS** (required by Stripe)
- [ ] Test with real card (small amount)
- [ ] Setup **monitoring** for failed payments
- [ ] Configure **email notifications** for disputes
- [ ] Review Stripe **fee structure** for your region
- [ ] Enable **3D Secure** for EU customers (Stripe handles automatically)
- [ ] Setup **tax calculations** if needed
- [ ] Configure **statement descriptor** in Stripe Dashboard

---

## Monitoring & Logging

### View Logs

**Application logs:**
```ruby
Rails.logger.info "Payment succeeded for booking..."
Rails.logger.warn "Payment failed for booking..."
Rails.logger.error "Failed to handle payment success..."
```

**Stripe Dashboard:**
- View all payments: https://dashboard.stripe.com/payments
- View webhooks: https://dashboard.stripe.com/webhooks
- View disputes: https://dashboard.stripe.com/disputes
- View customers: https://dashboard.stripe.com/customers

### Alert Setup

Monitor these events:
- Payment failures (high volume indicates card issues)
- Webhook failures (check endpoint is reachable)
- Disputes (respond within 7 days)
- Refund requests (track refund rate)

---

## API Examples

### Full Payment Flow (cURL)

**1. Create Intent:**
```bash
curl -X POST https://api.rentable.com/api/v1/payments/stripe/create_intent \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "booking_id": 123
  }'
```

**2. Check Status:**
```bash
curl -X GET https://api.rentable.com/api/v1/payments/stripe/payment_status/pi_3ABC123 \
  -H "Authorization: Bearer $TOKEN"
```

**3. Refund (if needed):**
```bash
curl -X POST https://api.rentable.com/api/v1/payments/stripe/refund \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "payment_intent_id": "pi_3ABC123",
    "amount_cents": 25000,
    "reason": "requested_by_customer"
  }'
```

---

## Support

### Stripe Support
- Dashboard: https://dashboard.stripe.com
- Documentation: https://stripe.com/docs/api
- Support: https://support.stripe.com

### Testing Resources
- Test cards: https://stripe.com/docs/testing
- Webhook testing: https://stripe.com/docs/webhooks/test
- Stripe CLI: https://stripe.com/docs/stripe-cli

---

## Summary

✅ **Complete Stripe Integration:**
- Payment intents (full/deposit/balance)
- Automatic customer creation
- Webhook handling (success/failure/disputes)
- Refund processing
- Payment status tracking
- Secure signature verification
- Automatic email notifications
- Database record keeping

**Your API is ready for production payments! 🎉**
