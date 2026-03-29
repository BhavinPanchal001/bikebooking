import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';

class ProductFirestoreService {
  ProductFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  /// Creates a new product document and returns the document ID.
  Future<String> addProduct(ProductModel product) async {
    final docRef = await _productsRef.add(product.toMap());
    return docRef.id;
  }

  /// Fetches all products, optionally filtered by one or more categories.
  Future<List<ProductModel>> getProducts({
    String? category,
    List<String>? categories,
  }) async {
    final normalizedCategory = category?.trim() ?? '';
    final normalizedCategories = _normalizeCategories(categories);
    final query = _buildCategoryQuery(
      category: normalizedCategory,
      categories: normalizedCategories,
      orderByCreatedAt: true,
    );

    try {
      final snapshot = await query.get();
      return _mapProducts(snapshot.docs);
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition') {
        rethrow;
      }

      final fallbackQuery = _buildCategoryQuery(
        category: normalizedCategory,
        categories: normalizedCategories,
        orderByCreatedAt: false,
      );
      final fallbackSnapshot = await fallbackQuery.get();
      return _sortByCreatedAtDesc(_mapProducts(fallbackSnapshot.docs));
    }
  }

  Stream<List<ProductModel>> watchProducts({
    String? category,
    List<String>? categories,
  }) {
    final normalizedCategory = category?.trim() ?? '';
    final normalizedCategories = _normalizeCategories(categories);
    final query = _buildCategoryQuery(
      category: normalizedCategory,
      categories: normalizedCategories,
      orderByCreatedAt: true,
    );

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
              .toList(growable: false),
        );
  }

  /// Fetches a single product by its document ID.
  Future<ProductModel?> getProductById(String id) async {
    final doc = await _productsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ProductModel.fromMap(doc.data()!, doc.id);
  }

  /// Fetches all products by a specific seller.
  Future<List<ProductModel>> getUserProducts(String userId) async {
    try {
      final snapshot = await _productsRef
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return _mapProducts(snapshot.docs);
    } on FirebaseException catch (error) {
      // Firestore can require an index for this query in some projects.
      if (error.code != 'failed-precondition') {
        rethrow;
      }

      final fallbackSnapshot =
          await _productsRef.where('sellerId', isEqualTo: userId).get();
      return _sortByCreatedAtDesc(_mapProducts(fallbackSnapshot.docs));
    }
  }

  /// Updates an existing product document.
  Future<void> updateProduct(String id, ProductModel product) async {
    await _productsRef.doc(id).update(product.toUpdateMap());
  }

  /// Deletes a product by its document ID.
  Future<void> deleteProduct(String id) async {
    await _productsRef.doc(id).delete();
  }

  Future<void> deleteProductsBySeller(String sellerId) async {
    final trimmedSellerId = sellerId.trim();
    if (trimmedSellerId.isEmpty) {
      return;
    }

    final snapshot =
        await _productsRef.where('sellerId', isEqualTo: trimmedSellerId).get();
    if (snapshot.docs.isEmpty) {
      return;
    }

    for (var index = 0; index < snapshot.docs.length; index += 450) {
      final batch = _firestore.batch();
      final chunk = snapshot.docs.skip(index).take(450);
      for (final doc in chunk) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  List<ProductModel> _mapProducts(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    return docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)).toList();
  }

  List<ProductModel> _sortByCreatedAtDesc(List<ProductModel> products) {
    products.sort((first, second) {
      final firstCreatedAt =
          first.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final secondCreatedAt =
          second.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return secondCreatedAt.compareTo(firstCreatedAt);
    });
    return products;
  }

  List<String> _normalizeCategories(List<String>? categories) {
    if (categories == null) {
      return const <String>[];
    }

    return categories
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  Query<Map<String, dynamic>> _buildCategoryQuery({
    required String category,
    required List<String> categories,
    required bool orderByCreatedAt,
  }) {
    Query<Map<String, dynamic>> query = _productsRef;

    if (categories.length > 1) {
      query = query.where('category', whereIn: categories.take(10).toList());
    } else if (categories.length == 1) {
      query = query.where('category', isEqualTo: categories.first);
    } else if (category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    if (orderByCreatedAt) {
      query = query.orderBy('createdAt', descending: true);
    }

    return query;
  }
}
