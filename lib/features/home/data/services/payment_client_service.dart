import 'package:cloud_functions/cloud_functions.dart';

/// Thin wrapper around the server-authoritative payment Callables.
///
/// All pricing, Razorpay order creation, and signature verification happen
/// server-side in Cloud Functions (`functions/src/payments.js`). The client
/// only knows about:
///   • the fee slug (e.g. `listing_fee`, `popular_boost`)
///   • the Razorpay order id returned by the server
///   • the signed success payload returned by Razorpay checkout
class PaymentClientService {
  PaymentClientService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Asks the server to mint a Razorpay order for [feeSlug] targeting
  /// [targetType] / [targetId]. The server validates the price against
  /// `/fee_config/{feeSlug}` and writes `/payments/{paymentId}` in the
  /// `created` state.
  ///
  /// Returns the parameters the Flutter checkout needs:
  ///   • `paymentId`: our `/payments/{id}`
  ///   • `razorpayOrderId`: pass to Razorpay checkout as `order_id`
  ///   • `razorpayKeyId`: publishable key (so the app does not hardcode it)
  ///   • `amountPaise`, `currency`
  Future<PaymentOrder> createOrder({
    required String feeSlug,
    required String targetType,
    required String targetId,
    Map<String, dynamic>? metadata,
  }) async {
    final callable = _functions.httpsCallable('createPaymentOrder');
    final result = await callable.call<Map<Object?, Object?>>(<String, dynamic>{
      'feeSlug': feeSlug,
      'target': <String, String>{
        'type': targetType,
        'id': targetId,
      },
      if (metadata != null) 'metadata': metadata,
    });
    final data = Map<String, dynamic>.from(result.data);
    return PaymentOrder.fromMap(data);
  }

  /// Confirms a successful Razorpay checkout with the server. The server
  /// re-verifies the HMAC signature and Razorpay payment amount before
  /// applying side-effects (marking the product boosted, unlocking the
  /// listing, etc.).
  Future<PaymentVerification> verify({
    required String paymentId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final callable = _functions.httpsCallable('verifyPaymentSignature');
    final result = await callable.call<Map<Object?, Object?>>(<String, dynamic>{
      'paymentId': paymentId,
      'razorpayOrderId': razorpayOrderId,
      'razorpayPaymentId': razorpayPaymentId,
      'razorpaySignature': razorpaySignature,
    });
    final data = Map<String, dynamic>.from(result.data);
    return PaymentVerification.fromMap(data);
  }
}

class PaymentOrder {
  const PaymentOrder({
    required this.paymentId,
    required this.razorpayOrderId,
    required this.razorpayKeyId,
    required this.amountPaise,
    required this.currency,
  });

  factory PaymentOrder.fromMap(Map<String, dynamic> data) {
    return PaymentOrder(
      paymentId: (data['paymentId'] as String?) ?? '',
      razorpayOrderId: (data['razorpayOrderId'] as String?) ?? '',
      razorpayKeyId: (data['razorpayKeyId'] as String?) ?? '',
      amountPaise: _toInt(data['amountPaise']) ?? 0,
      currency: (data['currency'] as String?) ?? 'INR',
    );
  }

  final String paymentId;
  final String razorpayOrderId;
  final String razorpayKeyId;
  final int amountPaise;
  final String currency;

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class PaymentVerification {
  const PaymentVerification({required this.status, required this.paymentId});

  factory PaymentVerification.fromMap(Map<String, dynamic> data) {
    return PaymentVerification(
      status: (data['status'] as String?) ?? 'paid',
      paymentId: (data['paymentId'] as String?) ?? '',
    );
  }

  final String status;
  final String paymentId;
}
