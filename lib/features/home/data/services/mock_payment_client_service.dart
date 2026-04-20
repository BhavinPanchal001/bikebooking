import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:bikebooking/features/home/data/models/product_status.dart';
import 'package:bikebooking/features/home/data/services/payment_client_service.dart';

/// DEMO-ONLY payment client that impersonates the Cloud Functions the
/// real [PaymentClientService] would call. Writes everything from the
/// mobile client so the mobile checkout screens can be exercised while
/// Cloud Functions are not deployed.
///
/// **NEVER SHIP. NEVER ENABLE IN PRODUCTION.** This bypasses every one
/// of the server-side safety invariants the PR was built around:
///
///   • No price validation (client reads `/fee_config/{slug}` directly,
///     so a patched client could pay ₹1 for a ₹199 boost).
///   • No HMAC signature verification on Razorpay success — the client
///     just trusts whatever Razorpay's onSuccess callback says.
///   • No audit log entries (those live in Cloud Functions).
///   • No webhook reconciliation (async-success / refund paths aren't
///     covered).
///
/// Guarded by the compile-time constant `kUseMockPayments` (from
/// `lib/core/config/demo_payments_config.dart`), which defaults to
/// `false`. Release/CI builds have no way of accidentally picking this
/// implementation.
class MockPaymentClientService implements PaymentClient {
  MockPaymentClientService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    String razorpayKeyId = 'rzp_test_Sb3lJVtmNxW4PH',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _razorpayKeyId = razorpayKeyId {
    assert(() {
      debugPrint(
        '⚠️  MockPaymentClientService is ACTIVE. '
        'Cloud Functions are bypassed. Do NOT ship this build.',
      );
      return true;
    }());
  }

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String _razorpayKeyId;

  static final _rand = Random.secure();

  /// Reads `/fee_config/{feeSlug}`, generates a local payment id, writes a
  /// `/payments/{id}` doc in `created` state, and returns a [PaymentOrder]
  /// that the app feeds to Razorpay checkout.
  ///
  /// The `razorpayOrderId` is returned empty — [RazorpayPaymentService]
  /// will then open checkout in key-only "standard" mode, which Razorpay
  /// supports for test keys.
  @override
  Future<PaymentOrder> createOrder({
    required String feeSlug,
    required String targetType,
    required String targetId,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before starting a payment.');
    }

    final feeDoc = await _firestore.collection('fee_config').doc(feeSlug).get();
    if (!feeDoc.exists) {
      throw StateError('Fee configuration "$feeSlug" not found.');
    }
    final fee = feeDoc.data() ?? const <String, dynamic>{};
    final amountPaise = _toInt(fee['amountPaise']) ?? 0;
    if (amountPaise <= 0) {
      throw StateError('Fee "$feeSlug" has no amount configured.');
    }
    final currency = (fee['currency'] as String?) ?? 'INR';

    final paymentId = _newId('pay');

    await _firestore.collection('payments').doc(paymentId).set(<String, dynamic>{
      'paymentId': paymentId,
      'userId': user.uid,
      'feeSlug': feeSlug,
      'feeKind': fee['kind'],
      'amountPaise': amountPaise,
      'currency': currency,
      'target': <String, dynamic>{
        'type': targetType,
        'id': targetId,
      },
      'status': 'created',
      'mock': true,
      'createdAt': FieldValue.serverTimestamp(),
      if (metadata != null) 'metadata': metadata,
    });

    return PaymentOrder(
      paymentId: paymentId,
      razorpayOrderId: '',
      razorpayKeyId: _razorpayKeyId,
      amountPaise: amountPaise,
      currency: currency,
    );
  }

  /// Pretends to verify the Razorpay signature. Updates the `/payments`
  /// doc to `paid` and applies the same side-effects the real Cloud
  /// Function would apply to the target document (product).
  @override
  Future<PaymentVerification> verify({
    required String paymentId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final paymentRef = _firestore.collection('payments').doc(paymentId);
    final snapshot = await paymentRef.get();
    if (!snapshot.exists) {
      throw StateError('Payment $paymentId not found.');
    }
    final payment = snapshot.data() ?? const <String, dynamic>{};
    final feeSlug = (payment['feeSlug'] as String?) ?? '';
    final feeKind = (payment['feeKind'] as String?) ?? '';
    final target = Map<String, dynamic>.from(
      payment['target'] as Map<dynamic, dynamic>? ?? const <dynamic, dynamic>{},
    );
    final targetType = (target['type'] as String?) ?? '';
    final targetId = (target['id'] as String?) ?? '';

    await paymentRef.update(<String, dynamic>{
      'status': 'paid',
      'razorpayPaymentId': razorpayPaymentId,
      'razorpayOrderId': razorpayOrderId,
      'razorpaySignature': razorpaySignature,
      'paidAt': FieldValue.serverTimestamp(),
      'mockVerifiedAt': FieldValue.serverTimestamp(),
    });

    if (targetType == 'product' && targetId.isNotEmpty) {
      await _applyProductSideEffects(
        productId: targetId,
        feeSlug: feeSlug,
        feeKind: feeKind,
        paymentId: paymentId,
      );
    }

    return PaymentVerification(status: 'paid', paymentId: paymentId);
  }

  Future<void> _applyProductSideEffects({
    required String productId,
    required String feeSlug,
    required String feeKind,
    required String paymentId,
  }) async {
    final productRef = _firestore.collection('products').doc(productId);
    final feeDoc = await _firestore.collection('fee_config').doc(feeSlug).get();
    final fee = feeDoc.data() ?? const <String, dynamic>{};
    final durationDays = _toInt(fee['durationDays']);

    if (feeKind == 'boost') {
      final now = DateTime.now();
      final expiresAt = durationDays != null && durationDays > 0
          ? now.add(Duration(days: durationDays))
          : now.add(const Duration(days: 7));
      await productRef.update(<String, dynamic>{
        'isBoosted': true,
        'boostPlanId': feeSlug,
        'boostPaymentId': paymentId,
        'boostStartedAt': Timestamp.fromDate(now),
        'boostExpiresAt': Timestamp.fromDate(expiresAt),
      });
    } else if (feeKind == 'listing_fee') {
      await productRef.update(<String, dynamic>{
        'listingFeePaid': true,
        'listingFeePaymentId': paymentId,
        'status': ProductStatus.active,
      });
    }
  }

  static String _newId(String prefix) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final nonce = _rand.nextInt(1 << 32).toRadixString(36);
    return '${prefix}_${now.toRadixString(36)}_$nonce';
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
