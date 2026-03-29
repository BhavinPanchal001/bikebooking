import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/recently_viewed_service.dart';
import 'package:bikebooking/features/home/data/services/seller_action_firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class HomeProductsController extends GetxController {
  HomeProductsController({
    ProductFirestoreService? firestoreService,
    RecentlyViewedService? recentlyViewedService,
    SellerActionFirestoreService? sellerActionService,
    LoginController? loginController,
  })  : _firestoreService = firestoreService ?? ProductFirestoreService(),
        _recentlyViewedService =
            recentlyViewedService ?? RecentlyViewedService(),
        _sellerActionService =
            sellerActionService ?? SellerActionFirestoreService(),
        _loginController = loginController ?? Get.find<LoginController>();

  final ProductFirestoreService _firestoreService;
  final RecentlyViewedService _recentlyViewedService;
  final SellerActionFirestoreService _sellerActionService;
  final LoginController _loginController;
  Set<String> _hiddenUserIds = <String>{};

  // ── Recently Viewed ──────────────────────────────────────────────────
  List<ProductModel> _recentlyViewed = [];
  List<ProductModel> get recentlyViewedProducts =>
      List.unmodifiable(_recentlyViewed);

  // ── Just Added ───────────────────────────────────────────────────────
  List<ProductModel> _justAdded = [];
  List<ProductModel> get justAddedProducts => List.unmodifiable(_justAdded);

  // ── Loading state ────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ── Helpers ──────────────────────────────────────────────────────────

  String? get _currentUserId {
    final id = _loginController.resolvedCurrentUserId.trim();
    return id.isNotEmpty ? id : null;
  }

  String get userPhotoUrl =>
      _loginController.currentUserProfile?.photoUrl ?? '';

  // ── Public API ───────────────────────────────────────────────────────

  /// Loads both recently-viewed and just-added sections in parallel.
  Future<void> loadProducts({bool showLoader = true}) async {
    if (showLoader) {
      _isLoading = true;
    }
    _errorMessage = null;
    update();

    try {
      _hiddenUserIds = await _loadHiddenUserIds();
      await Future.wait([
        _loadRecentlyViewed(),
        _loadJustAdded(),
      ]);
    } catch (error, stackTrace) {
      _errorMessage = 'Unable to load products right now.';
      debugPrint('Error loading home products: $error\n$stackTrace');
    } finally {
      _isLoading = false;
      update();
    }
  }

  /// Records that the user viewed a product, then refreshes the recently
  /// viewed list so the home page stays up-to-date.
  Future<void> recordProductView(ProductModel product) async {
    final userId = _currentUserId;
    if (userId == null) return;

    try {
      await _recentlyViewedService.recordView(
        userId: userId,
        product: product,
      );
      // Silently refresh recently-viewed in the background.
      await _loadRecentlyViewed();
      update();
    } catch (error, stackTrace) {
      debugPrint('Error recording product view: $error\n$stackTrace');
    }
  }

  // ── Private helpers ──────────────────────────────────────────────────

  Future<void> _loadRecentlyViewed() async {
    final userId = _currentUserId;
    if (userId == null) {
      _recentlyViewed = [];
      return;
    }

    try {
      final products =
          await _recentlyViewedService.getRecentProducts(userId, limit: 10);
      _recentlyViewed = _filterHiddenProducts(products);
    } catch (error, stackTrace) {
      debugPrint('Error loading recently viewed: $error\n$stackTrace');
      _recentlyViewed = [];
    }
  }

  Future<void> _loadJustAdded() async {
    try {
      // getProducts() already orders by createdAt descending.
      final allProducts = await _firestoreService.getProducts();
      final visibleProducts = _filterHiddenProducts(allProducts);
      _justAdded = visibleProducts.take(10).toList(growable: false);
    } catch (error, stackTrace) {
      debugPrint('Error loading just-added: $error\n$stackTrace');
      _justAdded = [];
    }
  }

  Future<Set<String>> _loadHiddenUserIds() async {
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return <String>{};
    }

    try {
      return await _sellerActionService.getHiddenUserIds(currentUserId);
    } catch (error, stackTrace) {
      debugPrint('Error loading hidden users: $error\n$stackTrace');
      return <String>{};
    }
  }

  List<ProductModel> _filterHiddenProducts(List<ProductModel> products) {
    if (_hiddenUserIds.isEmpty) {
      return products;
    }

    return products
        .where((product) => !_hiddenUserIds.contains(product.sellerId.trim()))
        .toList(growable: false);
  }
}
