import 'package:bikebooking/features/home/data/models/boost_plan.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/services/boost_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/razorpay_payment_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Manages the ad-specific boost flow:
///   1. User selects a product to boost
///   2. User picks a boost plan
///   3. Razorpay checkout opens
///   4. On success → boost fields saved to Firestore
class BoostController extends GetxController {
  BoostController({
    RazorpayPaymentService? paymentService,
    BoostFirestoreService? boostService,
  })  : _paymentService = paymentService ?? RazorpayPaymentService(),
        _boostService = boostService ?? BoostFirestoreService();

  final RazorpayPaymentService _paymentService;
  final BoostFirestoreService _boostService;

  // ── State ───────────────────────────────────────────────────────────────

  ProductModel? _targetProduct;
  ProductModel? get targetProduct => _targetProduct;

  BoostPlan _selectedPlan = BoostPlan.popular;
  BoostPlan get selectedPlan => _selectedPlan;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  String? _boostError;
  String? get boostError => _boostError;

  bool _paymentSucceeded = false;
  bool get paymentSucceeded => _paymentSucceeded;

  String? _lastPaymentId;
  String? get lastPaymentId => _lastPaymentId;

  // ── Callbacks for UI ────────────────────────────────────────────────────

  /// Called when the payment succeeds and the boost has been saved.
  /// The UI can use this to show the success bottom sheet.
  void Function()? onBoostSuccess;

  /// Called when the payment fails or is cancelled.
  void Function(String message)? onBoostError;

  // ── Public API ──────────────────────────────────────────────────────────

  /// Sets the product that the user wants to boost.
  void setTargetProduct(ProductModel product) {
    _targetProduct = product;
    _boostError = null;
    _paymentSucceeded = false;
    _lastPaymentId = null;
    update();
  }

  /// Updates which plan the user has selected.
  void selectPlan(BoostPlan plan) {
    _selectedPlan = plan;
    update();
  }

  /// Opens the Razorpay checkout for the currently selected plan + product.
  void startBoostPayment({String? userPhone, String? userEmail}) {
    final product = _targetProduct;
    final productId = product?.id;
    if (product == null || productId == null) {
      _boostError = 'No product selected for boosting.';
      update();
      return;
    }

    _isProcessing = true;
    _boostError = null;
    update();

    // Wire up callbacks
    _paymentService.onSuccess = _onPaymentSuccess;
    _paymentService.onError = _onPaymentError;
    _paymentService.onExternalWallet = _onExternalWallet;

    _paymentService.openCheckout(
      plan: _selectedPlan,
      productId: productId,
      userPhone: userPhone,
      userEmail: userEmail,
    );
  }

  /// Resets state after the boost flow is complete (success or cancelled).
  void resetBoostState() {
    _targetProduct = null;
    _selectedPlan = BoostPlan.popular;
    _isProcessing = false;
    _boostError = null;
    _paymentSucceeded = false;
    _lastPaymentId = null;
    update();
  }

  // ── Razorpay callbacks ──────────────────────────────────────────────────

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final productId = _targetProduct?.id;
    final paymentId = response.paymentId ?? '';

    if (productId == null || paymentId.isEmpty) {
      _isProcessing = false;
      _boostError = 'Payment succeeded but product or payment ID is missing.';
      update();
      onBoostError?.call(_boostError!);
      return;
    }

    try {
      await _boostService.boostProduct(
        productId: productId,
        planId: _selectedPlan.id,
        durationDays: _selectedPlan.durationDays,
        paymentId: paymentId,
      );
    } catch (error, stackTrace) {
      debugPrint('Error saving boost to Firestore: $error\n$stackTrace');
      _isProcessing = false;
      _boostError = 'Payment succeeded but we could not activate the boost. '
          'Please contact support with payment ID: $paymentId';
      update();
      onBoostError?.call(_boostError!);
      return;
    }

    _paymentSucceeded = true;
    _lastPaymentId = paymentId;
    _isProcessing = false;
    update();

    try {
      onBoostSuccess?.call();
    } catch (error, stackTrace) {
      debugPrint('Boost success callback failed: $error\n$stackTrace');
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    _isProcessing = false;

    final code = response.code ?? -1;
    // Code 2 = user cancelled the payment
    if (code == 2) {
      _boostError = null; // Don't show error for user cancellation
    } else {
      _boostError = response.message ?? 'Payment failed. Please try again.';
    }

    update();
    if (_boostError != null) {
      onBoostError?.call(_boostError!);
    }
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet selected: ${response.walletName}');
    // Razorpay handles the redirect automatically; no action needed here.
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────

  @override
  void onClose() {
    _paymentService.dispose();
    super.onClose();
  }
}
