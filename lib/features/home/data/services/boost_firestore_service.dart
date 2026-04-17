import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Manages boost-related data on product documents in Firestore.
///
/// Boost fields are stored directly on the product document to keep queries
/// simple and avoid extra reads.
class BoostFirestoreService {
  BoostFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  /// Applies a boost to the product document.
  ///
  /// Sets `isBoosted`, `boostPlanId`, `boostStartedAt`, `boostExpiresAt`, and
  /// `boostPaymentId` on the product document identified by [productId].
  Future<void> boostProduct({
    required String productId,
    required String planId,
    required int durationDays,
    required String paymentId,
  }) async {
    final now = DateTime.now();
    final expiresAt = now.add(Duration(days: durationDays));

    await _productsRef.doc(productId).update({
      'isBoosted': true,
      'boostPlanId': planId,
      'boostStartedAt': Timestamp.fromDate(now),
      'boostExpiresAt': Timestamp.fromDate(expiresAt),
      'boostPaymentId': paymentId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint(
      'Product $productId boosted with plan $planId until $expiresAt '
      '(payment: $paymentId)',
    );
  }

  /// Checks whether a product currently has an active (non-expired) boost.
  Future<bool> isProductBoosted(String productId) async {
    final doc = await _productsRef.doc(productId).get();
    final data = doc.data();
    if (data == null) return false;

    final isBoosted = data['isBoosted'] == true;
    if (!isBoosted) return false;

    final expiresAt = (data['boostExpiresAt'] as Timestamp?)?.toDate();
    if (expiresAt == null) return false;

    return expiresAt.isAfter(DateTime.now());
  }

  /// Clears boost fields when the boost has expired.
  Future<void> removeExpiredBoost(String productId) async {
    await _productsRef.doc(productId).update({
      'isBoosted': false,
      'boostPlanId': FieldValue.delete(),
      'boostStartedAt': FieldValue.delete(),
      'boostExpiresAt': FieldValue.delete(),
      'boostPaymentId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    debugPrint('Expired boost removed from product $productId');
  }

  /// Returns all currently-boosted products for the given [sellerId].
  Future<List<Map<String, dynamic>>> getBoostedProductsForSeller(
    String sellerId,
  ) async {
    final snapshot = await _productsRef
        .where('sellerId', isEqualTo: sellerId)
        .where('isBoosted', isEqualTo: true)
        .get();

    final now = DateTime.now();
    final results = <Map<String, dynamic>>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final expiresAt = (data['boostExpiresAt'] as Timestamp?)?.toDate();
      if (expiresAt != null && expiresAt.isAfter(now)) {
        results.add({...data, 'id': doc.id});
      }
    }

    return results;
  }
}
