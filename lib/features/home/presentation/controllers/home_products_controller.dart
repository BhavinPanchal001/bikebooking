import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/services/notification_dispatch_service.dart';
import 'package:bikebooking/features/home/data/services/boost_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/recently_viewed_service.dart';
import 'package:bikebooking/features/home/data/services/seller_action_firestore_service.dart';
import 'package:bikebooking/features/home/presentation/controllers/home_product_ranker.dart';
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
  Set<String>? _cachedHiddenUserIds;

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

  /// User's current location latitude for distance calculations.
  double? get userLatitude {
    final location = _loginController.currentUserProfile?.location;
    return location?.isComplete == true ? location?.latitude : null;
  }

  /// User's current location longitude for distance calculations.
  double? get userLongitude {
    final location = _loginController.currentUserProfile?.location;
    return location?.isComplete == true ? location?.longitude : null;
  }

  // ── Public API ───────────────────────────────────────────────────────

  /// Loads both recently-viewed and just-added sections in parallel.
  Future<void> loadProducts({bool showLoader = true}) async {
    if (showLoader) {
      _isLoading = true;
    }
    _errorMessage = null;
    update();

    try {
      _hiddenUserIds = await _loadHiddenUserIds(forceRefresh: !showLoader);
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
      final shouldNotifySeller = await _recentlyViewedService.recordView(
        userId: userId,
        product: product,
      );
      if (shouldNotifySeller &&
          product.sellerId.trim().isNotEmpty &&
          product.sellerId.trim() != userId &&
          Get.isRegistered<NotificationDispatchService>()) {
        final viewer = _loginController.currentUserProfile;
        final viewerName = viewer?.displayNameLabel ?? 'Someone';
        await Get.find<NotificationDispatchService>().dispatchNotification(
          recipientId: product.sellerId,
          title: 'Someone viewed your ad',
          body:
              '$viewerName viewed ${product.title.trim().isNotEmpty ? product.title.trim() : 'your listing'}.',
          type: 'product_view',
          senderId: userId,
          senderName: viewerName,
          senderPhotoUrl: viewer?.photoUrl,
          targetRoute: '/my_listing',
          productId: product.id,
          documentId:
              'product_view_${product.id?.trim() ?? 'listing'}_${userId.trim()}',
        );
      }
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

      final location = _loginController.currentUserProfile?.location;
      final selectedAddress = location?.address ?? '';
      final hasCoords = location != null && location.isComplete;
      _justAdded = rankJustAddedProductsByLocation(
        products: visibleProducts,
        selectedLocationAddress: selectedAddress,
        userLatitude: hasCoords ? location.latitude : null,
        userLongitude: hasCoords ? location.longitude : null,
        limit: 10,
        onExpiredBoost: _cleanupExpiredBoost,
      );
    } catch (error, stackTrace) {
      debugPrint('Error loading just-added: $error\n$stackTrace');
      _justAdded = [];
    }
  }

  /// Clears stale boost fields from a product whose boost has expired.
  Future<void> _cleanupExpiredBoost(String productId) async {
    try {
      await BoostFirestoreService().removeExpiredBoost(productId);
    } catch (e) {
      debugPrint('Failed to cleanup expired boost for $productId: $e');
    }
  }

  Future<Set<String>> _loadHiddenUserIds({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedHiddenUserIds != null) {
      return _cachedHiddenUserIds!;
    }
    final currentUserId = _currentUserId;
    if (currentUserId == null) {
      return <String>{};
    }

    try {
      _cachedHiddenUserIds = await _sellerActionService.getHiddenUserIds(currentUserId);
      return _cachedHiddenUserIds!;
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
