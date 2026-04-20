# Payment gateway demo mode

> **⚠️  Demo mode is a dev-only bypass that skips the Cloud Functions the
> real payment flow depends on. It is **NOT** safe to ship.** Release builds
> (`flutter build release`, any CI build without the explicit flag) ignore
> demo mode entirely and go through the real `createPaymentOrder` /
> `verifyPaymentSignature` Cloud Functions.

The demo lets you exercise the mobile boost / listing-fee checkout screens
(including the real Razorpay checkout UI with a test card) without having
Cloud Functions deployed. It is intended for one thing: validating the
**mobile UX** of the MS3 #1 PR while Cloud Functions are blocked on a
developer who can run `firebase deploy --only functions`.

## What it covers

- Boost purchase flow end-to-end: plan selection → Razorpay checkout →
  "success" → `isBoosted=true` on the product.
- Listing-fee flow end-to-end: new listing → "Awaiting Payment" →
  Razorpay checkout → `status=active` on the product.
- All UI copy, loading states, error banners, success animations.

## What it does NOT cover

- No HMAC signature verification. The mock doesn't validate the Razorpay
  response at all.
- No server-side audit log (`/audit_logs` entries only come from Cloud
  Functions).
- No webhook reconciliation. Async-success / refund callbacks from
  Razorpay are ignored.
- No admin-panel refund path. The Refund button in the admin panel still
  calls `refundPayment` and still fails with `not-found` until Cloud
  Functions deploy.
- No pre-payment stale-cleanup (scheduled function) runs.

## Enabling demo mode

Run the app with `--dart-define=USE_MOCK_PAYMENTS=true`:

```bash
flutter run --dart-define=USE_MOCK_PAYMENTS=true
```

The flag is read at compile time from
`lib/core/config/demo_payments_config.dart` into the constant
`kUseMockPayments`. It defaults to `false`, so regular
`flutter run` / `flutter build release` builds never take the mock path.

On startup the mock logs a loud warning via `debugPrint` so it's visible
in the debug console:

```
⚠️  MockPaymentClientService is ACTIVE. Cloud Functions are bypassed.
Do NOT ship this build.
```

## Required Firestore rules

Client writes to `/payments/{id}` are blocked by the production rules
(`allow write: if false;`). For demo mode, temporarily loosen them to
allow signed-in users to create their own payment docs. **Paste this
block into Firebase Console → Firestore Database → Rules → Publish**:

```
// ⚠️  DEMO-MODE-ONLY — revert before production
match /payments/{paymentId} {
  allow read: if request.auth != null;
  allow create, update: if request.auth != null
                        && request.resource.data.userId == request.auth.uid;
  allow delete: if false;
}
```

Revert to the strict rule after demo is done:

```
match /payments/{paymentId} {
  allow read: if request.auth != null;
  allow write: if false;  // server-only via admin SDK
}
```

## Razorpay test card

Use the test card in the Razorpay checkout UI:

- Card number: `4111 1111 1111 1111`
- CVV: any 3 digits (`123`)
- Expiry: any future date (`12/30`)
- Name: any
- OTP (if asked): `1111`

The test key hardcoded as the Razorpay fallback
(`rzp_test_Sb3lJVtmNxW4PH`) is a public Razorpay demo key. If you want to
use your own, pass `--dart-define=RAZORPAY_KEY_ID=...` or pass the key
explicitly into `MockPaymentClientService`.

## Reverting to the production path

When Cloud Functions are deployed, turn demo mode off:

1. Run the app **without** `--dart-define=USE_MOCK_PAYMENTS=true`. The
   factory will return the real `PaymentClientService`.
2. Re-deploy the strict Firestore rules (the revert snippet above).

## Files to strip before the PR goes to production

If you want to strip the demo entirely from the codebase:

1. Delete `lib/core/config/demo_payments_config.dart`.
2. Delete `lib/features/home/data/services/mock_payment_client_service.dart`.
3. Delete `lib/features/home/data/services/payment_client_factory.dart`.
4. In `boost_controller.dart` and `listing_fee_controller.dart`:
   - Remove the `demo_payments_config` and `payment_client_factory`
     imports.
   - Change the `PaymentClient` field type back to `PaymentClientService`.
   - Change `?? createPaymentClient()` back to `?? PaymentClientService()`.
   - Remove the `requireSignedPayload` branching in
     `_onPaymentSuccess`.
5. In `razorpay_payment_service.dart`, remove the
   `if (orderId.isNotEmpty)` guard so `order_id` is always included.
6. Remove `DEMO_MODE.md`.

The `PaymentClient` abstract interface can stay (it's nice for testability)
or be inlined back into `PaymentClientService` — either is fine.
