import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/models/product_status.dart';

class ProductFirestoreService {
  ProductFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore,
        _addProductOverride = null,
        _getProductsOverride = null,
        _getUserProductsOverride = null,
        _watchProductByIdOverride = null,
        _updateProductOverride = null,
        _updateProductStatusOverride = null,
        _deleteProductOverride = null;

  ProductFirestoreService.withOverrides({
    FirebaseFirestore? firestore,
    Future<String> Function(ProductModel product)? addProductOverride,
    Future<List<ProductModel>> Function(
      String? category,
      List<String>? categories,
      bool activeOnly,
    )? getProductsOverride,
    Future<List<ProductModel>> Function(String userId)? getUserProductsOverride,
    Stream<ProductModel?> Function(String id, bool includeInactive)?
        watchProductByIdOverride,
    Future<void> Function(String id, ProductModel product)?
        updateProductOverride,
    Future<void> Function(String id, String status)?
        updateProductStatusOverride,
    Future<void> Function(String id)? deleteProductOverride,
  })  : _firestore = firestore,
        _addProductOverride = addProductOverride,
        _getProductsOverride = getProductsOverride,
        _getUserProductsOverride = getUserProductsOverride,
        _watchProductByIdOverride = watchProductByIdOverride,
        _updateProductOverride = updateProductOverride,
        _updateProductStatusOverride = updateProductStatusOverride,
        _deleteProductOverride = deleteProductOverride;

  final FirebaseFirestore? _firestore;
  final Future<String> Function(ProductModel product)? _addProductOverride;
  final Future<List<ProductModel>> Function(
    String? category,
    List<String>? categories,
    bool activeOnly,
  )? _getProductsOverride;
  final Future<List<ProductModel>> Function(String userId)?
      _getUserProductsOverride;
  final Stream<ProductModel?> Function(String id, bool includeInactive)?
      _watchProductByIdOverride;
  final Future<void> Function(String id, ProductModel product)?
      _updateProductOverride;
  final Future<void> Function(String id, String status)?
      _updateProductStatusOverride;
  final Future<void> Function(String id)? _deleteProductOverride;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      (_firestore ?? FirebaseFirestore.instance).collection('products');

  /// Creates a new product document and returns the document ID.
  Future<String> addProduct(ProductModel product) async {
    final addProductOverride = _addProductOverride;
    if (addProductOverride != null) {
      return addProductOverride(product);
    }

    final docRef = await _productsRef.add(product.toMap());
    return docRef.id;
  }

  /// Fetches all products, optionally filtered by one or more categories.
  Future<List<ProductModel>> getProducts({
    String? category,
    List<String>? categories,
    bool activeOnly = true,
  }) async {
    final getProductsOverride = _getProductsOverride;
    if (getProductsOverride != null) {
      return getProductsOverride(category, categories, activeOnly);
    }

    final normalizedCategory = category?.trim() ?? '';
    final normalizedCategories = _normalizeCategories(categories);
    final query = _buildCategoryQuery(
      category: normalizedCategory,
      categories: normalizedCategories,
      orderByCreatedAt: true,
    );

    try {
      final snapshot = await query.get();
      return _filterByStatus(
        _mapProducts(snapshot.docs),
        activeOnly: activeOnly,
      );
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
      return _sortByCreatedAtDesc(
        _filterByStatus(
          _mapProducts(fallbackSnapshot.docs),
          activeOnly: activeOnly,
        ),
      );
    }
  }

  Stream<List<ProductModel>> watchProducts({
    String? category,
    List<String>? categories,
    bool activeOnly = true,
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
              .where((product) => !activeOnly || product.isActive)
              .toList(growable: false),
        );
  }

  /// Fetches a single product by its document ID.
  Future<ProductModel?> getProductById(
    String id, {
    bool includeInactive = false,
  }) async {
    final doc = await _productsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    final product = ProductModel.fromMap(doc.data()!, doc.id);
    if (!includeInactive && !product.isActive) {
      return null;
    }
    return product;
  }

  Stream<ProductModel?> watchProductById(
    String id, {
    bool includeInactive = false,
  }) {
    final watchProductByIdOverride = _watchProductByIdOverride;
    if (watchProductByIdOverride != null) {
      return watchProductByIdOverride(id, includeInactive);
    }

    final normalizedId = id.trim();
    if (normalizedId.isEmpty) {
      return Stream<ProductModel?>.value(null);
    }

    return _productsRef.doc(normalizedId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        return null;
      }

      final product = ProductModel.fromMap(data, doc.id);
      if (!includeInactive && !product.isActive) {
        return null;
      }
      return product;
    });
  }

  /// Fetches all products by a specific seller.
  Future<List<ProductModel>> getUserProducts(
    String userId, {
    bool includeInactive = false,
  }) async {
    final getUserProductsOverride = _getUserProductsOverride;
    if (getUserProductsOverride != null) {
      final products = await getUserProductsOverride(userId);
      return _filterForSeller(
        products,
        includeInactive: includeInactive,
      );
    }

    try {
      final snapshot = await _productsRef
          .where('sellerId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return _filterForSeller(
        _mapProducts(snapshot.docs),
        includeInactive: includeInactive,
      );
    } on FirebaseException catch (error) {
      // Firestore can require an index for this query in some projects.
      if (error.code != 'failed-precondition') {
        rethrow;
      }

      final fallbackSnapshot =
          await _productsRef.where('sellerId', isEqualTo: userId).get();
      return _sortByCreatedAtDesc(
        _filterForSeller(
          _mapProducts(fallbackSnapshot.docs),
          includeInactive: includeInactive,
        ),
      );
    }
  }

  /// Updates an existing product document.
  Future<void> updateProduct(String id, ProductModel product) async {
    final updateProductOverride = _updateProductOverride;
    if (updateProductOverride != null) {
      return updateProductOverride(id, product);
    }

    await _productsRef.doc(id).update(product.toUpdateMap());
  }

  Future<void> updateProductStatus(String id, String status) async {
    final updateProductStatusOverride = _updateProductStatusOverride;
    if (updateProductStatusOverride != null) {
      return updateProductStatusOverride(id, status);
    }

    await _productsRef.doc(id).update({
      'status': ProductStatus.normalize(status),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes a product by its document ID.
  Future<void> deleteProduct(String id) async {
    final deleteProductOverride = _deleteProductOverride;
    if (deleteProductOverride != null) {
      return deleteProductOverride(id);
    }

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

  List<ProductModel> _filterByStatus(
    List<ProductModel> products, {
    required bool activeOnly,
  }) {
    if (!activeOnly) {
      return products;
    }

    return products
        .where((product) => product.isActive)
        .toList(growable: false);
  }

  List<ProductModel> _filterForSeller(
    List<ProductModel> products, {
    required bool includeInactive,
  }) {
    if (includeInactive) {
      return products;
    }

    return products
        .where((product) => product.isActive)
        .toList(growable: false);
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
