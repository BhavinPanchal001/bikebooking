import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/models/product_status.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class MyListingController extends GetxController {
  MyListingController({
    ProductFirestoreService? firestoreService,
    String Function()? currentSellerIdProvider,
  })  : _firestoreService = firestoreService ?? ProductFirestoreService(),
        _currentSellerIdProvider = currentSellerIdProvider;

  final ProductFirestoreService _firestoreService;
  final String Function()? _currentSellerIdProvider;

  List<ProductModel> _products = [];
  List<ProductModel> get products => List.unmodifiable(_products);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _actionErrorMessage;
  String? get actionErrorMessage => _actionErrorMessage;

  final Set<String> _deletingProductIds = <String>{};
  final Set<String> _statusUpdatingProductIds = <String>{};

  bool isDeleting(String? productId) =>
      productId != null && _deletingProductIds.contains(productId);

  bool isUpdatingStatus(String? productId) =>
      productId != null && _statusUpdatingProductIds.contains(productId);

  Future<void> loadProducts({bool showLoader = true}) async {
    if (showLoader) {
      _isLoading = true;
    }
    _errorMessage = null;
    update();

    final sellerId = _resolveCurrentSellerId();
    if (sellerId.isEmpty) {
      _products = [];
      _isLoading = false;
      _errorMessage = 'Sign in to view the products you have posted.';
      update();
      return;
    }

    try {
      _products = await _firestoreService.getUserProducts(
        sellerId,
        includeInactive: true,
      );
    } on FirebaseException catch (error, stackTrace) {
      _errorMessage = _friendlyLoadError(error);
      debugPrint('Error loading products: $error\n$stackTrace');
    } catch (error, stackTrace) {
      _errorMessage = 'Unable to load your posts right now.';
      debugPrint('Error loading products: $error\n$stackTrace');
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> refreshProducts() {
    return loadProducts(showLoader: false);
  }

  Future<bool> deleteProduct(String productId) async {
    if (_deletingProductIds.contains(productId)) {
      return false;
    }

    _actionErrorMessage = null;
    _deletingProductIds.add(productId);
    update();

    try {
      await _firestoreService.deleteProduct(productId);
      _products.removeWhere((product) => product.id == productId);
      return true;
    } on FirebaseException catch (error, stackTrace) {
      _actionErrorMessage = _friendlyDeleteError(error);
      debugPrint('Error deleting product: $error\n$stackTrace');
      return false;
    } catch (error, stackTrace) {
      _actionErrorMessage = 'Unable to remove this post right now.';
      debugPrint('Error deleting product: $error\n$stackTrace');
      return false;
    } finally {
      _deletingProductIds.remove(productId);
      update();
    }
  }

  Future<bool> updateProductStatus({
    required String productId,
    required String status,
  }) async {
    if (_statusUpdatingProductIds.contains(productId)) {
      return false;
    }

    _actionErrorMessage = null;
    _statusUpdatingProductIds.add(productId);
    update();

    try {
      final normalizedStatus = ProductStatus.normalize(status);
      await _firestoreService.updateProductStatus(productId, normalizedStatus);
      final productIndex =
          _products.indexWhere((product) => product.id == productId);
      if (productIndex >= 0) {
        _products[productIndex] = _products[productIndex].copyWith(
          status: normalizedStatus,
          updatedAt: DateTime.now(),
        );
      }
      return true;
    } on FirebaseException catch (error, stackTrace) {
      _actionErrorMessage = _friendlyStatusError(error);
      debugPrint('Error updating product status: $error\n$stackTrace');
      return false;
    } catch (error, stackTrace) {
      _actionErrorMessage = 'Unable to update this listing right now.';
      debugPrint('Error updating product status: $error\n$stackTrace');
      return false;
    } finally {
      _statusUpdatingProductIds.remove(productId);
      update();
    }
  }

  String _resolveCurrentSellerId() {
    final providedSellerId = _currentSellerIdProvider?.call().trim() ?? '';
    if (providedSellerId.isNotEmpty) {
      return providedSellerId;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      return firebaseUser.uid;
    }

    if (Get.isRegistered<LoginController>()) {
      return Get.find<LoginController>().currentUserProfile?.id ?? '';
    }

    return '';
  }

  String _friendlyLoadError(FirebaseException error) {
    final normalizedCode = error.code.toLowerCase();

    if (normalizedCode == 'permission-denied' ||
        normalizedCode == 'unauthenticated') {
      return 'Firebase blocked access to your posts. Update your Firestore rules to allow reading products for this user.';
    }
    if (normalizedCode == 'unavailable' ||
        normalizedCode == 'network-request-failed') {
      return 'Check your internet connection and try again.';
    }
    if (normalizedCode == 'failed-precondition') {
      return 'Firestore needs an index for this query. Create the suggested index in Firebase Console if this keeps happening.';
    }

    final message = error.message?.trim() ?? '';
    if (message.isNotEmpty) {
      return message;
    }

    return 'Unable to load your posts right now.';
  }

  String _friendlyDeleteError(FirebaseException error) {
    final normalizedCode = error.code.toLowerCase();

    if (normalizedCode == 'permission-denied' ||
        normalizedCode == 'unauthenticated') {
      return 'Firebase blocked deleting this post. Update your Firestore rules to allow it.';
    }
    if (normalizedCode == 'not-found') {
      return 'This product no longer exists.';
    }

    final message = error.message?.trim() ?? '';
    if (message.isNotEmpty) {
      return message;
    }

    return 'Unable to remove this post right now.';
  }

  String _friendlyStatusError(FirebaseException error) {
    final normalizedCode = error.code.toLowerCase();

    if (normalizedCode == 'permission-denied' ||
        normalizedCode == 'unauthenticated') {
      return 'Firebase blocked updating this listing. Update your Firestore rules to allow it.';
    }
    if (normalizedCode == 'not-found') {
      return 'This product no longer exists.';
    }

    final message = error.message?.trim() ?? '';
    if (message.isNotEmpty) {
      return message;
    }

    return 'Unable to update this listing right now.';
  }
}
