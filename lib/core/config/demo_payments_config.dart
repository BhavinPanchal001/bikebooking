/// Compile-time flag that swaps in the client-side [MockPaymentClientService]
/// in place of the server-authoritative [PaymentClientService].
///
/// Enable it for local UAT runs when Cloud Functions are not yet deployed:
///
/// ```
/// flutter run --dart-define=USE_MOCK_PAYMENTS=true
/// ```
///
/// The default is `false`, which means regular release builds and CI always
/// use the real Cloud Functions path and have no way of accidentally
/// shipping the mock.
///
/// WHAT IT DOES
///
///   • Skips `createPaymentOrder` / `verifyPaymentSignature` Cloud Function
///     calls. The client reads `/fee_config/{slug}` directly to get the
///     amount and then writes `/payments/{paymentId}` + flips the
///     payment-gated product fields itself.
///
///   • Opens Razorpay checkout in "standard" mode (no server-minted
///     `order_id`) so you can still see the real Razorpay UI, pay with the
///     test card `4111 1111 1111 1111` (CVV `123`, any future expiry), and
///     watch the app state flip.
///
/// WHAT IT DOES **NOT** DO
///
///   • No HMAC signature verification — anyone with the app can flip
///     payment-gated fields by patching the client.
///   • No webhook path — async-success / refund events from Razorpay are
///     ignored.
///   • No admin refund path — the admin panel "Refund" button still fails.
///   • The Firestore rules must be temporarily loosened to allow the client
///     to write to `/payments`. See `DEMO_MODE.md`.
///
/// Strip before production. See the top of `DEMO_MODE.md` for the exact
/// files to revert.
const bool kUseMockPayments =
    bool.fromEnvironment('USE_MOCK_PAYMENTS', defaultValue: false);
