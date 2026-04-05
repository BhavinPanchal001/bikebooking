import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FavoritesFirestoreService {
  FavoritesFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore,
        _watchFavoriteProductIdsOverride = null,
        _addFavoriteOverride = null,
        _removeFavoriteOverride = null,
        _clearFavoritesOverride = null;

  FavoritesFirestoreService.withOverrides({
    FirebaseFirestore? firestore,
    Stream<List<String>> Function(String userId)?
        watchFavoriteProductIdsOverride,
    Future<void> Function(String userId, ProductModel product)?
        addFavoriteOverride,
    Future<void> Function(String userId, String productId)?
        removeFavoriteOverride,
    Future<void> Function(String userId)? clearFavoritesOverride,
  })  : _firestore = firestore,
        _watchFavoriteProductIdsOverride = watchFavoriteProductIdsOverride,
        _addFavoriteOverride = addFavoriteOverride,
        _removeFavoriteOverride = removeFavoriteOverride,
        _clearFavoritesOverride = clearFavoritesOverride;

  final FirebaseFirestore? _firestore;
  final Stream<List<String>> Function(String userId)?
      _watchFavoriteProductIdsOverride;
  final Future<void> Function(String userId, ProductModel product)?
      _addFavoriteOverride;
  final Future<void> Function(String userId, String productId)?
      _removeFavoriteOverride;
  final Future<void> Function(String userId)? _clearFavoritesOverride;

  CollectionReference<Map<String, dynamic>> _favoritesRef(String userId) =>
      (_firestore ?? FirebaseFirestore.instance)
          .collection('users')
          .doc(userId)
          .collection('favorites');

  Stream<List<String>> watchFavoriteProductIds(String userId) {
    final watchFavoriteProductIdsOverride = _watchFavoriteProductIdsOverride;
    if (watchFavoriteProductIdsOverride != null) {
      return watchFavoriteProductIdsOverride(userId);
    }

    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return Stream<List<String>>.value(const <String>[]);
    }

    return _favoritesRef(normalizedUserId)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.id.trim())
              .where((id) => id.isNotEmpty)
              .toList(growable: false),
        );
  }

  Future<void> addFavorite({
    required String userId,
    required ProductModel product,
  }) async {
    final addFavoriteOverride = _addFavoriteOverride;
    if (addFavoriteOverride != null) {
      return addFavoriteOverride(userId, product);
    }

    final normalizedUserId = userId.trim();
    final productId = product.id?.trim() ?? '';
    if (normalizedUserId.isEmpty || productId.isEmpty) {
      return;
    }

    await _favoritesRef(normalizedUserId).doc(productId).set({
      'productId': productId,
      'savedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeFavorite({
    required String userId,
    required String productId,
  }) async {
    final removeFavoriteOverride = _removeFavoriteOverride;
    if (removeFavoriteOverride != null) {
      return removeFavoriteOverride(userId, productId);
    }

    final normalizedUserId = userId.trim();
    final normalizedProductId = productId.trim();
    if (normalizedUserId.isEmpty || normalizedProductId.isEmpty) {
      return;
    }

    await _favoritesRef(normalizedUserId).doc(normalizedProductId).delete();
  }

  Future<void> clearFavorites(String userId) async {
    final clearFavoritesOverride = _clearFavoritesOverride;
    if (clearFavoritesOverride != null) {
      return clearFavoritesOverride(userId);
    }

    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return;
    }

    final snapshot = await _favoritesRef(normalizedUserId).get();
    if (snapshot.docs.isEmpty) {
      return;
    }

    final firestore = _firestore ?? FirebaseFirestore.instance;
    for (var index = 0; index < snapshot.docs.length; index += 450) {
      final batch = firestore.batch();
      final chunk = snapshot.docs.skip(index).take(450);
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
