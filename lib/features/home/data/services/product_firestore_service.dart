import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';

class ProductFirestoreService {
  ProductFirestoreService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _productsRef => _firestore.collection('products');

  /// Creates a new product document and returns the document ID.
  Future<String> addProduct(ProductModel product) async {
    final docRef = await _productsRef.add(product.toMap());
    return docRef.id;
  }

  /// Fetches all products, optionally filtered by category.
  Future<List<ProductModel>> getProducts({String? category}) async {
    Query<Map<String, dynamic>> query = _productsRef.orderBy('createdAt', descending: true);

    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)).toList();
  }

  /// Fetches a single product by its document ID.
  Future<ProductModel?> getProductById(String id) async {
    final doc = await _productsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ProductModel.fromMap(doc.data()!, doc.id);
  }

  /// Fetches all products by a specific seller.
  Future<List<ProductModel>> getUserProducts(String userId) async {
    final snapshot =
        await _productsRef.where('sellerId', isEqualTo: userId).orderBy('createdAt', descending: true).get();

    return snapshot.docs.map((doc) => ProductModel.fromMap(doc.data(), doc.id)).toList();
  }

  /// Updates an existing product document.
  Future<void> updateProduct(String id, ProductModel product) async {
    await _productsRef.doc(id).update(product.toUpdateMap());
  }

  /// Deletes a product by its document ID.
  Future<void> deleteProduct(String id) async {
    await _productsRef.doc(id).delete();
  }
}
