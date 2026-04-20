import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:bikebooking/core/config/demo_payments_config.dart';
import 'package:bikebooking/features/home/data/models/boost_plan.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/services/fee_config_service.dart';
import 'package:bikebooking/features/home/data/services/payment_client_factory.dart';
import 'package:bikebooking/features/home/data/services/payment_client_service.dart';
import 'package:bikebooking/features/home/data/services/razorpay_payment_service.dart';

/// Manages the boost purchase flow.
///
/// Flow (server-authoritative):
///   1. User selects a product + plan.
///   2. Controller calls `createPaymentOrder` — server validates the plan
///      against `/fee_config` and mints a Razorpay order.
///   3. Razorpay checkout opens (driven by the server-minted order id).
///   4. On success, controller calls `verifyPaymentSignature` — the server
///      re-verifies the HMAC signature and flips the product's boost fields
///      using the admin SDK. The client **never** writes the boost fields.
class BoostController extends GetxController {
  BoostController({
    RazorpayPaymentService? paymentService,
    PaymentClient? paymentClient,
    FeeConfigService? feeConfigService,
  })  : _paymentService = paymentService ?? RazorpayPaymentService(),
        _paymentClient = paymentClient ?? createPaymentClient(),
        _feeConfigService = feeConfigService ?? FeeConfigService();

  final RazorpayPaymentService _paymentService;
  final PaymentClient _paymentClient;
  final FeeConfigService _feeConfigService;

  // ── State ───────────────────────────────────────────────────────────────

  ProductModel? _targetProduct;
  ProductModel? get targetProduct => _targetProduct;

  List<BoostPlan> _availablePlans = BoostPlan.allPlans;
  List<BoostPlan> get availablePlans => _availablePlans;

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

  // Server-minted payment state — needed to verify after checkout.
  String? _pendingPaymentDocId;
  String? _pendingRazorpayOrderId;

  // Held so we can cancel the Firestore listener when the controller is
  // disposed; otherwise the stream keeps calling `update()` on a closed
  // GetxController and leaks the underlying snapshot listener.
  StreamSubscription<List<BoostPlan>>? _plansSubscription;

  // ── Callbacks for UI ────────────────────────────────────────────────────

  void Function()? onBoostSuccess;
  void Function(String message)? onBoostError;

  // ── Public API ──────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _plansSubscription = _feeConfigService.watchBoostPlans().listen((plans) {
      if (plans.isEmpty) return;
      _availablePlans = plans;
      // Keep the currently selected plan if the admin still has it; else
      // fall back to the middle-priced plan.
      final currentStillValid = plans.any((p) => p.id == _selectedPlan.id);
      if (!currentStillValid) {
        _selectedPlan = plans[plans.length ~/ 2];
      }
      update();
    }, onError: (Object error, StackTrace stackTrace) {
      debugPrint('Unable to stream fee_config: $error\n$stackTrace');
    });
  }

  void setTargetProduct(ProductModel product) {
    _targetProduct = product;
    _boostError = null;
    _paymentSucceeded = false;
    _lastPaymentId = null;
    _pendingPaymentDocId = null;
    _pendingRazorpayOrderId = null;
    update();
  }

  void selectPlan(BoostPlan plan) {
    _selectedPlan = plan;
    update();
  }

  /// Starts the boost flow. Mints a server order, then opens checkout.
  Future<void> startBoostPayment({String? userPhone, String? userEmail}) async {
    final product = _targetProduct;
    final productId = product?.id;
    if (product == null || productId == null) {
      _boostError = 'No product selected for boosting.';
      update();
      onBoostError?.call(_boostError!);
      return;
    }

    _isProcessing = true;
    _boostError = null;
    update();

    try {
      final order = await _paymentClient.createOrder(
        feeSlug: _selectedPlan.id,
        targetType: 'product',
        targetId: productId,
      );
      _pendingPaymentDocId = order.paymentId;
      _pendingRazorpayOrderId = order.razorpayOrderId;

      _paymentService.onSuccess = _onPaymentSuccess;
      _paymentService.onError = _onPaymentError;
      _paymentService.onExternalWallet = _onExternalWallet;

      _paymentService.openCheckoutForOrder(
        orderId: order.razorpayOrderId,
        amountPaise: order.amountPaise,
        currency: order.currency,
        displayName: _selectedPlan.name,
        description: _selectedPlan.subtitle,
        apiKey: order.razorpayKeyId,
        userPhone: userPhone,
        userEmail: userEmail,
        notes: <String, String>{
          'product_id': productId,
          'plan_id': _selectedPlan.id,
        },
      );
    } on FirebaseFunctionsException catch (error, stackTrace) {
      debugPrint('createPaymentOrder failed: $error\n$stackTrace');
      _isProcessing = false;
      _boostError = error.message ?? 'Unable to start payment. Please retry.';
      update();
      onBoostError?.call(_boostError!);
    } catch (error, stackTrace) {
      debugPrint('startBoostPayment error: $error\n$stackTrace');
      _isProcessing = false;
      _boostError = 'Unable to start payment. Please retry.';
      update();
      onBoostError?.call(_boostError!);
    }
  }

  void resetBoostState() {
    _targetProduct = null;
    _selectedPlan = _availablePlans.isNotEmpty
        ? _availablePlans[_availablePlans.length ~/ 2]
        : BoostPlan.popular;
    _isProcessing = false;
    _boostError = null;
    _paymentSucceeded = false;
    _lastPaymentId = null;
    _pendingPaymentDocId = null;
    _pendingRazorpayOrderId = null;
    update();
  }

  // ── Razorpay callbacks ──────────────────────────────────────────────────

  Future<void> _onPaymentSuccess(PaymentSuccessResponse response) async {
    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';
    final orderId = response.orderId ?? _pendingRazorpayOrderId ?? '';
    final pendingPaymentDoc = _pendingPaymentDocId;

    // In the demo mock path we open Razorpay checkout WITHOUT a
    // server-minted order_id, so Razorpay's success response may come
    // back with an empty signature / orderId. The mock verifier doesn't
    // care about either, so we only enforce them in the real path.
    final requireSignedPayload = !kUseMockPayments;
    if (paymentId.isEmpty ||
        (requireSignedPayload && signature.isEmpty) ||
        (requireSignedPayload && orderId.isEmpty) ||
        pendingPaymentDoc == null ||
        pendingPaymentDoc.isEmpty) {
      _isProcessing = false;
      _boostError = 'Payment succeeded but we could not verify the signature. '
          'Please contact support with payment ID: $paymentId';
      update();
      onBoostError?.call(_boostError!);
      return;
    }

    try {
      await _paymentClient.verify(
        paymentId: pendingPaymentDoc,
        razorpayOrderId: orderId,
        razorpayPaymentId: paymentId,
        razorpaySignature: signature,
      );
    } on FirebaseFunctionsException catch (error, stackTrace) {
      debugPrint('verifyPaymentSignature failed: $error\n$stackTrace');
      _isProcessing = false;
      _boostError =
          'Payment captured but verification failed. Support ID: $paymentId';
      update();
      onBoostError?.call(_boostError!);
      return;
    } catch (error, stackTrace) {
      debugPrint('verify error: $error\n$stackTrace');
      _isProcessing = false;
      _boostError =
          'Payment captured but verification failed. Support ID: $paymentId';
      update();
      onBoostError?.call(_boostError!);
      return;
    }

    _paymentSucceeded = true;
    _lastPaymentId = paymentId;
    _isProcessing = false;
    _pendingPaymentDocId = null;
    _pendingRazorpayOrderId = null;
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
      _boostError = null;
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
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────

  @override
  void onClose() {
    _plansSubscription?.cancel();
    _plansSubscription = null;
    _paymentService.dispose();
    super.onClose();
  }
}
