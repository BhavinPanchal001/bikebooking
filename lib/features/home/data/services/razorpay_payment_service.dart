import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:bikebooking/features/home/data/models/boost_plan.dart';

/// Thin wrapper around the Razorpay Flutter SDK.
///
/// Call [openCheckout] to start a payment. Results are delivered through the
/// [onSuccess], [onError], and [onExternalWallet] callbacks that must be set
/// before opening checkout.
class RazorpayPaymentService {
  RazorpayPaymentService({String? apiKey})
      : _apiKey = apiKey ?? 'rzp_test_Sb3lJVtmNxW4PH';

  final String _apiKey;
  late final Razorpay _razorpay;
  bool _initialized = false;

  /// Must be set before calling [openCheckout].
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

  /// Opens the Razorpay checkout sheet for the given [plan].
  ///
  /// [productId] is passed through as a note so we can identify the product
  /// in the success callback.
  void openCheckout({
    required BoostPlan plan,
    required String productId,
    String? userPhone,
    String? userEmail,
  }) {
    _ensureInitialized();

    final options = <String, dynamic>{
      'key': _apiKey,
      'amount': plan.priceInPaise,
      'name': 'Bikenest',
      'description': '${plan.name} – ${plan.subtitle}',
      'notes': <String, String>{
        'product_id': productId,
        'plan_id': plan.id,
      },
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
