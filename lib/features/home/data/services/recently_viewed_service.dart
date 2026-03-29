import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';

/// Manages the per-user "recently viewed products" sub-collection.
///
/// Firestore path: `users/{userId}/recentlyViewed/{productId}`
///
/// Each document stores a `viewedAt` timestamp and basic product metadata
/// so we can show the card without an extra products-lookup on first load.
class RecentlyViewedService {
  RecentlyViewedService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const int _maxRecentItems = 20;

  CollectionReference<Map<String, dynamic>> _recentRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('recentlyViewed');

  /// Records that the current user viewed [product].
  ///
  /// Uses the product's document ID as the doc key so a second view just
  /// bumps the timestamp instead of creating a duplicate.
  Future<void> recordView({
    required String userId,
    required ProductModel product,
  }) async {
    final productId = product.id?.trim() ?? '';
    if (productId.isEmpty || userId.trim().isEmpty) return;

    try {
      await _recentRef(userId).doc(productId).set({
        'productId': productId,
        'viewedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Housekeeping: trim old entries beyond the cap.
      await _trimOldEntries(userId);
    } on FirebaseException catch (error) {
      if (_isPermissionDenied(error)) {
        return;
      }
      rethrow;
    }
  }

  /// Returns the product IDs the user most recently viewed, newest first.
  Future<List<String>> getRecentProductIds(String userId,
      {int limit = 10}) async {
    if (userId.trim().isEmpty) return [];

    try {
      final snapshot = await _recentRef(userId)
          .orderBy('viewedAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => doc.id)
          .where((id) => id.trim().isNotEmpty)
          .toList(growable: false);
    } on FirebaseException catch (error) {
      if (_isPermissionDenied(error)) {
        return [];
      }
      rethrow;
    }
  }

  /// Fetches full [ProductModel]s for the recently viewed product IDs.
  ///
  /// Firestore `whereIn` supports a max of 30 values; we limit to 10 by
  /// default so this is safe.
  Future<List<ProductModel>> getRecentProducts(String userId,
      {int limit = 10}) async {
    try {
      final ids = await getRecentProductIds(userId, limit: limit);
      if (ids.isEmpty) return [];

      final productsRef = _firestore.collection('products');
      final snapshot =
          await productsRef.where(FieldPath.documentId, whereIn: ids).get();

      final productMap = <String, ProductModel>{};
      for (final doc in snapshot.docs) {
        if (doc.data().isNotEmpty) {
          productMap[doc.id] = ProductModel.fromMap(doc.data(), doc.id);
        }
      }

      // Preserve the recently-viewed order.
      return ids
          .where((id) => productMap.containsKey(id))
          .map((id) => productMap[id]!)
          .toList(growable: false);
    } on FirebaseException catch (error) {
      if (_isPermissionDenied(error)) {
        return [];
      }
      rethrow;
    }
  }

  Future<void> _trimOldEntries(String userId) async {
    try {
      final snapshot =
          await _recentRef(userId).orderBy('viewedAt', descending: true).get();

      if (snapshot.docs.length <= _maxRecentItems) return;

      final batch = _firestore.batch();
      final toDelete = snapshot.docs.sublist(_maxRecentItems);
      for (final doc in toDelete) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (error) {
      if (_isPermissionDenied(error)) {
        return;
      }
      rethrow;
    }
  }

  bool _isPermissionDenied(FirebaseException error) =>
      error.code == 'permission-denied';
}
