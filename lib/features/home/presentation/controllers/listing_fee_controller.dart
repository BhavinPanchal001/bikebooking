import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:bikebooking/core/config/demo_payments_config.dart';
import 'package:bikebooking/features/home/data/services/fee_config_service.dart';
import 'package:bikebooking/features/home/data/services/payment_client_factory.dart';
import 'package:bikebooking/features/home/data/services/payment_client_service.dart';
import 'package:bikebooking/features/home/data/services/razorpay_payment_service.dart';

/// Drives the one-time listing-fee payment.
///
/// The fee is resolved from `/fee_config/listing_fee` (admin-configured).
/// If the fee document is absent or inactive, the product is published
/// immediately without a paywall.
///
/// Flow mirrors [BoostController]:
///   1. `createPaymentOrder` (feeSlug: `listing_fee`, target: product)
///   2. Razorpay checkout with the server-minted order id
///   3. `verifyPaymentSignature` → server flips product.status to `active`
class ListingFeeController extends GetxController {
  ListingFeeController({
    RazorpayPaymentService? paymentService,
    PaymentClient? paymentClient,
    FeeConfigService? feeConfigService,
    String feeSlug = 'listing_fee',
  })  : _paymentService = paymentService ?? RazorpayPaymentService(),
        _paymentClient = paymentClient ?? createPaymentClient(),
        _feeConfigService = feeConfigService ?? FeeConfigService(),
        _feeSlug = feeSlug;

  final RazorpayPaymentService _paymentService;
  final PaymentClient _paymentClient;
  final FeeConfigService _feeConfigService;
  final String _feeSlug;

  // ── State ───────────────────────────────────────────────────────────────

  FeeConfigEntry? _feeConfig;
  FeeConfigEntry? get feeConfig => _feeConfig;

  bool get isFeeActive => _feeConfig != null && _feeConfig!.amountPaise > 0;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String? _error;
  String? get error => _error;

  String? _pendingProductId;
  String? get pendingProductId => _pendingProductId;

  String? _pendingPaymentDocId;
  String? _pendingRazorpayOrderId;

  bool _paid = false;
  bool get paid => _paid;

  void Function()? onPaid;
  void Function(String message)? onFailed;

  // ── Public API ──────────────────────────────────────────────────────────

  /// Fetches the current listing-fee configuration. Returns `null` if the
  /// fee is not configured (in which case callers should skip the paywall).
  Future<FeeConfigEntry?> loadFeeConfig() async {
    try {
      _feeConfig = await _feeConfigService.getActiveFee(_feeSlug);
      update();
      return _feeConfig;
    } catch (error, stackTrace) {
      debugPrint('loadFeeConfig error: $error\n$stackTrace');
      _feeConfig = null;
      update();
      return null;
    }
  }

  /// Opens the Razorpay checkout for the listing fee on [productId].
  Future<void> payListingFee({
    required String productId,
    String? userPhone,
    String? userEmail,
  }) async {
    if (_feeConfig == null || _feeConfig!.amountPaise <= 0) {
      _error = 'Listing fee is not configured.';
      update();
      onFailed?.call(_error!);
      return;
    }

    _isProcessing = true;
    _error = null;
    _paid = false;
    _pendingProductId = productId;
    update();

    try {
      final order = await _paymentClient.createOrder(
        feeSlug: _feeSlug,
        targetType: 'product',
        targetId: productId,
      );
      _pendingPaymentDocId = order.paymentId;
      _pendingRazorpayOrderId = order.razorpayOrderId;

      _paymentService.onSuccess = _onPaymentSuccess;
      _paymentService.onError = _onPaymentError;

      _paymentService.openCheckoutForOrder(
        orderId: order.razorpayOrderId,
        amountPaise: order.amountPaise,
        currency: order.currency,
        displayName: _feeConfig!.displayName,
        description: _feeConfig!.subtitle ?? 'One-time listing fee',
        apiKey: order.razorpayKeyId,
        userPhone: userPhone,
        userEmail: userEmail,
        notes: <String, String>{
          'product_id': productId,
          'fee_slug': _feeSlug,
        },
      );
    } on FirebaseFunctionsException catch (error, stackTrace) {
      debugPrint('createPaymentOrder (listing_fee) failed: $error\n$stackTrace');
      _isProcessing = false;
      _error = error.message ?? 'Unable to start payment. Please retry.';
      update();
      onFailed?.call(_error!);
    } catch (error, stackTrace) {
      debugPrint('payListingFee error: $error\n$stackTrace');
      _isProcessing = false;
      _error = 'Unable to start payment. Please retry.';
      update();
      onFailed?.call(_error!);
    }
  }

  // ── Razorpay callbacks ──────────────────────────────────────────────────

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final razorpayPaymentId = response.paymentId ?? '';
    final razorpaySignature = response.signature ?? '';
    final razorpayOrderId = response.orderId ?? _pendingRazorpayOrderId ?? '';
    final pendingPaymentDoc = _pendingPaymentDocId;

    // Demo mock path: Razorpay checkout runs without a server-minted
    // order_id, so signature / orderId may be empty. The mock verifier
    // doesn't validate them, so only enforce presence on the real path.
    final requireSignedPayload = !kUseMockPayments;
    if (razorpayPaymentId.isEmpty ||
        (requireSignedPayload && razorpaySignature.isEmpty) ||
        (requireSignedPayload && razorpayOrderId.isEmpty) ||
        pendingPaymentDoc == null ||
        pendingPaymentDoc.isEmpty) {
      _isProcessing = false;
      _error = 'Payment succeeded but verification data was incomplete. '
          'Contact support with payment ID: $razorpayPaymentId';
      update();
      onFailed?.call(_error!);
      return;
    }

    try {
      await _paymentClient.verify(
        paymentId: pendingPaymentDoc,
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );
    } catch (error, stackTrace) {
      debugPrint('verify (listing_fee) failed: $error\n$stackTrace');
      _isProcessing = false;
      _error =
          'Payment captured but verification failed. Support ID: $razorpayPaymentId';
      update();
      onFailed?.call(_error!);
      return;
    }

    _paid = true;
    _isProcessing = false;
    _pendingPaymentDocId = null;
    _pendingRazorpayOrderId = null;
    update();
    onPaid?.call();
  }

  void _onPaymentError(PaymentFailureResponse response) {
    _isProcessing = false;
    final code = response.code ?? -1;
    // Code 2 = user cancelled the payment
    if (code == 2) {
      _error = null;
    } else {
      _error = response.message ?? 'Payment failed. Please try again.';
    }
    update();
    if (_error != null) {
      onFailed?.call(_error!);
    }
  }

  @override
  void onClose() {
    _paymentService.dispose();
    super.onClose();
  }
}
