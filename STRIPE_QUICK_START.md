# Stripe Integration - Quick Start Guide

## 🚀 For Mobile/Frontend Developers

### Setup (One-Time)

1. **Get API Keys from Backend Team:**
   - `STRIPE_PUBLISHABLE_KEY` (starts with `pk_test_` or `pk_live_`)
   - API Base URL (e.g., `https://api.rentable.com`)

2. **Install Stripe SDK:**

   **React Native:**
   ```bash
   npm install @stripe/stripe-react-native
   ```

   **Flutter:**
   ```bash
   flutter pub add flutter_stripe
   ```

   **iOS (Swift):**
   ```ruby
   pod 'StripePaymentSheet'
   ```

   **Android (Kotlin):**
   ```gradle
   implementation 'com.stripe:stripe-android:20.x.x'
   ```

---

## 💳 Complete Payment in 3 Steps

### Step 1: Create Payment Intent (Backend Call)

```javascript
const response = await fetch('https://api.rentable.com/api/v1/payments/stripe/create_intent', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${userToken}`
  },
  body: JSON.stringify({
    booking_id: 123,
    // Optional: for deposit (e.g., 30% deposit)
    deposit_percent: 30
    // OR specify exact amount
    // amount_cents: 50000  // $500.00
  })
});

const { client_secret } = await response.json();
```

### Step 2: Present Stripe Payment UI

**React Native:**
```javascript
import { useStripe } from '@stripe/stripe-react-native';

const { presentPaymentSheet, initPaymentSheet } = useStripe();

// Initialize
await initPaymentSheet({
  paymentIntentClientSecret: client_secret,
  merchantDisplayName: 'Rentable',
});

// Present to user
const { error } = await presentPaymentSheet();

if (!error) {
  // ✅ Payment successful!
  // No further action needed - webhook updates booking automatically
  navigation.navigate('BookingConfirmation');
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
// ✅ Success! Booking updated automatically
```

**iOS (Swift):**
```swift
import StripePaymentSheet

var configuration = PaymentSheet.Configuration()
configuration.merchantDisplayName = "Rentable"

let paymentSheet = PaymentSheet(
  paymentIntentClientSecret: clientSecret,
  configuration: configuration
)

paymentSheet.present(from: self) { result in
  switch result {
  case .completed:
    // ✅ Payment successful!
    self.showConfirmation()
  case .canceled:
    // User canceled
  case .failed(let error):
    self.showError(error)
  }
}
```

### Step 3: Done! 🎉

That's it! The payment is processed. The backend webhook automatically:
- ✅ Creates payment record
- ✅ Updates booking status
- ✅ Sends confirmation email to customer
- ✅ Updates balance

---

## 📱 Example: Full Booking + Payment Flow

```javascript
// 1. User creates booking
const bookingResponse = await fetch('https://api.rentable.com/api/v1/bookings', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
  body: JSON.stringify({
    booking: {
      start_date: "2026-03-01",
      end_date: "2026-03-05",
      customer_name: "John Doe",
      customer_email: "john@example.com",
      customer_phone: "+1234567890",
      line_items: [
        { bookable_type: "Product", bookable_id: 1, quantity: 1 }
      ]
    }
  })
});

const booking = await bookingResponse.json();

// 2. Create payment intent for 30% deposit
const paymentResponse = await fetch('https://api.rentable.com/api/v1/payments/stripe/create_intent', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
  body: JSON.stringify({
    booking_id: booking.booking.id,
    deposit_percent: 30
  })
});

const { client_secret } = await paymentResponse.json();

// 3. Present Stripe payment UI
await initPaymentSheet({ paymentIntentClientSecret: client_secret });
const { error } = await presentPaymentSheet();

if (!error) {
  // 4. Payment successful! Show confirmation
  Alert.alert('Success', 'Booking confirmed! Check your email for details.');
}
```

---

## 🔍 Check Payment Status (Optional)

If you need to verify payment status:

```javascript
const statusResponse = await fetch(
  `https://api.rentable.com/api/v1/payments/stripe/payment_status/${paymentIntentId}`,
  {
    headers: { 'Authorization': `Bearer ${token}` }
  }
);

const { status } = await statusResponse.json();
// status: "succeeded", "processing", "requires_action", etc.
```

---

## 🧪 Testing

### Test Cards (Stripe Test Mode)

**✅ Success:**
```
Card: 4242 4242 4242 4242
Exp: 12/34 (any future date)
CVC: 123 (any 3 digits)
ZIP: 12345 (any 5 digits)
```

**🔐 Requires 3D Secure:**
```
Card: 4000 0027 6000 3184
```
→ Stripe will show authentication screen

**❌ Card Declined:**
```
Card: 4000 0000 0000 0002
```

**💸 Insufficient Funds:**
```
Card: 4000 0000 0000 9995
```

---

## ⚡ Common Scenarios

### Scenario 1: Pay 30% Deposit Now, Rest Later

```javascript
// First payment (30% deposit)
const intent1 = await createPaymentIntent({
  booking_id: 123,
  deposit_percent: 30
});

// ... customer pays via Stripe UI ...

// Later: Second payment (remaining 70%)
const intent2 = await createPaymentIntent({
  booking_id: 123
  // No params = charge full balance_due
});
```

### Scenario 2: Full Payment Immediately

```javascript
const intent = await createPaymentIntent({
  booking_id: 123
  // No params = charge full total
});
```

### Scenario 3: Custom Amount

```javascript
const intent = await createPaymentIntent({
  booking_id: 123,
  amount_cents: 100000  // Exactly $1000.00
});
```

---

## 🛠️ Error Handling

```javascript
try {
  const { error } = await presentPaymentSheet();

  if (error) {
    switch (error.code) {
      case 'Canceled':
        // User closed the payment sheet
        showMessage('Payment canceled');
        break;
      case 'Failed':
        // Payment failed
        showError('Payment failed. Please try again.');
        break;
      default:
        showError(error.message);
    }
  } else {
    // ✅ Success!
    navigateToConfirmation();
  }
} catch (e) {
  console.error('Payment error:', e);
  showError('Something went wrong');
}
```

---

## 📝 API Reference (Quick)

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/payments/stripe/create_intent` | POST | Create payment intent |
| `/payments/stripe/payment_status/:id` | GET | Check payment status |
| `/payments/stripe/confirm_payment` | POST | Manual confirmation |
| `/payments/stripe/refund` | POST | Refund (admin only) |

---

## 🎯 Best Practices

1. **Always use `client_secret` immediately** - Don't store it
2. **Check payment status** after app re-opens (in case of crash)
3. **Handle 3D Secure** - Stripe SDK does this automatically
4. **Show loading state** while payment processes
5. **Don't double-charge** - Check if payment already exists
6. **Test with all card types** before production

---

## 💡 Tips

- **Stripe handles PCI compliance** - Never touch card numbers
- **Webhook updates booking** - No polling needed
- **Test mode works everywhere** - No credit card charged
- **3D Secure is automatic** - SDK handles authentication
- **Works offline** - Payment intent cached

---

## 🆘 Troubleshooting

**"Invalid API key"**
→ Check `STRIPE_PUBLISHABLE_KEY` is correct

**"Booking not found"**
→ Make sure `booking_id` exists and user has access

**"Amount too small"**
→ Minimum payment is $0.50 (50 cents)

**Payment succeeds but booking not updated**
→ Check webhook is configured correctly (backend issue)

---

## 📚 More Resources

- **Stripe Docs:** https://stripe.com/docs
- **React Native:** https://stripe.com/docs/payments/accept-a-payment?platform=react-native
- **Flutter:** https://pub.dev/packages/flutter_stripe
- **iOS:** https://stripe.com/docs/payments/accept-a-payment?platform=ios
- **Android:** https://stripe.com/docs/payments/accept-a-payment?platform=android

---

**Need Help?** Contact backend team or check `STRIPE_INTEGRATION.md` for detailed guide.
