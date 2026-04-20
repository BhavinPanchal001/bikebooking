import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Thin wrapper around the Razorpay Flutter SDK.
///
/// The checkout is driven by a server-minted Razorpay order id — the client
/// never authors prices. Pass the [orderId], [amountPaise], and publishable
/// [apiKey] returned by `createPaymentOrder` into [openCheckoutForOrder].
///
/// Callbacks [onSuccess], [onError], and [onExternalWallet] must be set
/// before opening checkout.
class RazorpayPaymentService {
  RazorpayPaymentService({String? fallbackApiKey})
      : _fallbackApiKey = fallbackApiKey ?? 'rzp_test_Sb3lJVtmNxW4PH';

  final String _fallbackApiKey;
  late final Razorpay _razorpay;
  bool _initialized = false;

  void Function(PaymentSuccessResponse)? onSuccess;
  void Function(PaymentFailureResponse)? onError;
  void Function(ExternalWalletResponse)? onExternalWallet;

  // ── Lifecycle ───────────────────────────────────────────────────────────

  void _ensureInitialized() {
    if (_initialized) return;

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleWallet);
    _initialized = true;
  }

  void dispose() {
    if (_initialized) {
      _razorpay.clear();
      _initialized = false;
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Opens Razorpay checkout for a server-minted order.
  ///
  /// Razorpay will include a `razorpay_signature` in the success payload
  /// which the server later verifies with HMAC-SHA256.
  void openCheckoutForOrder({
    required String orderId,
    required int amountPaise,
    required String currency,
    required String displayName,
    String? description,
    String? apiKey,
    String? userPhone,
    String? userEmail,
    Map<String, String> notes = const <String, String>{},
  }) {
    _ensureInitialized();

    final options = <String, dynamic>{
      'key': (apiKey != null && apiKey.isNotEmpty) ? apiKey : _fallbackApiKey,
      'amount': amountPaise,
      'currency': currency,
      // Standard Razorpay checkout also supports key-only mode (no
      // server-minted order id) for demo / test flows. Omit the key
      // entirely in that case so the SDK doesn't try to match an empty
      // string against Razorpay's order registry.
      if (orderId.isNotEmpty) 'order_id': orderId,
      'name': 'Bikenest',
      if (description != null && description.isNotEmpty)
        'description': description,
      'notes': notes,
      'prefill': <String, String>{
        if (userPhone != null && userPhone.isNotEmpty) 'contact': userPhone,
        if (userEmail != null && userEmail.isNotEmpty) 'email': userEmail,
      },
      'theme': <String, String>{
        'color': '#2E4475',
      },
    };

    _razorpay.open(options);
  }

  // ── Internal handlers ───────────────────────────────────────────────────

  void _handleSuccess(PaymentSuccessResponse response) {
    debugPrint('Razorpay payment success: ${response.paymentId}');
    onSuccess?.call(response);
  }

  void _handleError(PaymentFailureResponse response) {
    debugPrint(
      'Razorpay payment error: code=${response.code}, '
      'message=${response.message}',
    );
    onError?.call(response);
  }

  void _handleWallet(ExternalWalletResponse response) {
    debugPrint('Razorpay external wallet: ${response.walletName}');
    onExternalWallet?.call(response);
  }
}
