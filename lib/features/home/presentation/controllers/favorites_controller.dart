import 'dart:async';

import 'package:bikebooking/core/widgets/app_snackbar.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/services/favorites_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/product_firestore_service.dart';
import 'package:bikebooking/features/home/data/services/seller_action_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FavoritesController extends GetxController {
  FavoritesController({
    FavoritesFirestoreService? favoritesService,
    ProductFirestoreService? productFirestoreService,
    SellerActionFirestoreService? sellerActionService,
    LoginController? loginController,
    String Function()? currentUserIdProvider,
    Future<Set<String>> Function(String userId)? hiddenUserIdsLoader,
    Future<bool> Function()? firestoreSessionEnsurer,
    String Function()? firestoreSessionErrorProvider,
    void Function(String title, String message)? favoriteErrorNotifier,
  })  : _favoritesService = favoritesService ?? FavoritesFirestoreService(),
        _productFirestoreService =
            productFirestoreService ?? ProductFirestoreService(),
        _sellerActionService = sellerActionService,
        _loginController = loginController ??
            (Get.isRegistered<LoginController>()
                ? Get.find<LoginController>()
                : null),
        _currentUserIdProvider = currentUserIdProvider,
        _hiddenUserIdsLoader = hiddenUserIdsLoader,
        _firestoreSessionEnsurer = firestoreSessionEnsurer,
        _firestoreSessionErrorProvider = firestoreSessionErrorProvider,
        _favoriteErrorNotifier = favoriteErrorNotifier;

  final FavoritesFirestoreService _favoritesService;
  final ProductFirestoreService _productFirestoreService;
  final SellerActionFirestoreService? _sellerActionService;
  final LoginController? _loginController;
  final String Function()? _currentUserIdProvider;
  final Future<Set<String>> Function(String userId)? _hiddenUserIdsLoader;
  final Future<bool> Function()? _firestoreSessionEnsurer;
  final String Function()? _firestoreSessionErrorProvider;
  final void Function(String title, String message)? _favoriteErrorNotifier;
  final Set<String> _favoriteIds = <String>{};
  final List<String> _favoriteOrder = <String>[];
  final Map<String, ProductModel> _favoritesByKey = <String, ProductModel>{};
  final Map<String, StreamSubscription<ProductModel?>> _productSubscriptions =
      <String, StreamSubscription<ProductModel?>>{};
  Set<String> _hiddenUserIds = <String>{};
  StreamSubscription<List<String>>? _favoriteIdsSubscription;
  String _boundUserId = '';

  List<ProductModel> get favorites => _favoriteOrder
      .map((productId) => _favoritesByKey[productId])
      .whereType<ProductModel>()
      .where((product) => product.isActive)
      .where((product) => !_hiddenUserIds.contains(product.sellerId.trim()))
      .toList(growable: false);

  bool get hasFavorites => favorites.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    unawaited(bindToCurrentUser());
  }

  @override
  void onClose() {
    unawaited(_favoriteIdsSubscription?.cancel() ?? Future<void>.value());
    for (final subscription in _productSubscriptions.values) {
      unawaited(subscription.cancel());
    }
    _productSubscriptions.clear();
    super.onClose();
  }

  bool isFavorite(ProductModel product) {
    final productId = _productId(product);
    if (productId.isEmpty) {
      return false;
    }
    return _favoriteIds.contains(productId);
  }

  bool toggleFavorite(ProductModel product) {
    final productId = _productId(product);
    if (productId.isEmpty) {
      return false;
    }

    final userId = _currentUserId;
    if (userId.isEmpty) {
      _showFavoriteError('Sign in to save favorites.');
      return isFavorite(product);
    }

    if (_favoriteIds.contains(productId)) {
      final existingProduct = _favoritesByKey[productId] ?? product;
      _favoriteIds.remove(productId);
      _favoriteOrder.remove(productId);
      _favoritesByKey.remove(productId);
      update();
      unawaited(
        _persistRemoveFavorite(
          userId: userId,
          productId: productId,
          fallbackProduct: existingProduct,
        ),
      );
      return false;
    }

    _favoriteIds.add(productId);
    _favoriteOrder.remove(productId);
    _favoriteOrder.insert(0, productId);
    _favoritesByKey[productId] = product;
    update();
    unawaited(
      _persistAddFavorite(
        userId: userId,
        product: product,
      ),
    );
    return true;
  }

  void removeFavorite(ProductModel product) {
    if (!isFavorite(product)) {
      return;
    }
    toggleFavorite(product);
  }

  void clearFavorites() {
    _boundUserId = '';
    unawaited(_favoriteIdsSubscription?.cancel() ?? Future<void>.value());
    _favoriteIdsSubscription = null;
    for (final subscription in _productSubscriptions.values) {
      unawaited(subscription.cancel());
    }
    _productSubscriptions.clear();
    _favoriteIds.clear();
    _favoriteOrder.clear();
    _favoritesByKey.clear();
    _hiddenUserIds = <String>{};
    update();
  }

  Future<void> bindToCurrentUser() async {
    final currentUserId = _currentUserId;
    if (currentUserId.isEmpty) {
      clearFavorites();
      return;
    }

    if (_boundUserId == currentUserId && _favoriteIdsSubscription != null) {
      await refreshHiddenUsers();
      return;
    }

    clearFavorites();
    _boundUserId = currentUserId;
    await refreshHiddenUsers();
    _favoriteIdsSubscription =
        _favoritesService.watchFavoriteProductIds(currentUserId).listen(
      _handleFavoriteIdsChanged,
      onError: (error, stackTrace) {
        debugPrint(
          'Error watching favorites for $currentUserId: $error\n$stackTrace',
        );
      },
    );
  }

  Future<void> refreshHiddenUsers() async {
    final currentUserId = _currentUserId;
    if (currentUserId.isEmpty) {
      _hiddenUserIds = <String>{};
      update();
      return;
    }

    try {
      final hiddenUserIdsLoader = _hiddenUserIdsLoader;
      if (hiddenUserIdsLoader != null) {
        _hiddenUserIds = await hiddenUserIdsLoader(currentUserId);
      } else {
        _hiddenUserIds =
            await (_sellerActionService ?? SellerActionFirestoreService())
                .getHiddenUserIds(currentUserId);
      }
    } catch (_) {
      _hiddenUserIds = <String>{};
    }
    update();
  }

  void _handleFavoriteIdsChanged(List<String> productIds) {
    final normalizedIds = productIds
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final nextFavoriteIds = normalizedIds.toSet();

    for (final productId
        in _productSubscriptions.keys.toList(growable: false)) {
      if (!nextFavoriteIds.contains(productId)) {
        final subscription = _productSubscriptions.remove(productId);
        unawaited(subscription?.cancel() ?? Future<void>.value());
        _favoritesByKey.remove(productId);
      }
    }

    _favoriteIds
      ..clear()
      ..addAll(nextFavoriteIds);
    _favoriteOrder
      ..clear()
      ..addAll(normalizedIds);

    for (final productId in normalizedIds) {
      _productSubscriptions.putIfAbsent(
        productId,
        () => _productFirestoreService
            .watchProductById(
          productId,
          includeInactive: true,
        )
            .listen(
          (product) {
            if (!_favoriteIds.contains(productId)) {
              return;
            }

            if (product == null) {
              _favoritesByKey.remove(productId);
            } else {
              _favoritesByKey[productId] = product;
            }
            update();
          },
          onError: (error, stackTrace) {
            debugPrint(
              'Error watching favorite product $productId: '
              '$error\n$stackTrace',
            );
          },
        ),
      );
    }
    update();
  }

  Future<void> _persistAddFavorite({
    required String userId,
    required ProductModel product,
  }) async {
    final productId = _productId(product);
    if (productId.isEmpty) {
      return;
    }

    try {
      await _favoritesService.addFavorite(
        userId: userId,
        product: product,
      );
      return;
    } catch (error, stackTrace) {
      var failedError = error;
      var failedStackTrace = stackTrace;

      if (_isSessionRecoveryError(error)) {
        final hasSession = await _ensureFirestoreSession();
        if (hasSession) {
          try {
            await _favoritesService.addFavorite(
              userId: userId,
              product: product,
            );
            return;
          } catch (retryError, retryStackTrace) {
            failedError = retryError;
            failedStackTrace = retryStackTrace;
          }
        }
      }

      debugPrint(
        'Error saving favorite $productId: $failedError\n$failedStackTrace',
      );
      if (_isSessionRecoveryError(failedError)) {
        _showFavoriteError(_favoriteSessionErrorMessage());
      }
      if (_boundUserId != userId || !_favoriteIds.contains(productId)) {
        return;
      }

      _favoriteIds.remove(productId);
      _favoriteOrder.remove(productId);
      _favoritesByKey.remove(productId);
      update();
    }
  }

  Future<void> _persistRemoveFavorite({
    required String userId,
    required String productId,
    required ProductModel fallbackProduct,
  }) async {
    try {
      await _favoritesService.removeFavorite(
        userId: userId,
        productId: productId,
      );
      return;
    } catch (error, stackTrace) {
      var failedError = error;
      var failedStackTrace = stackTrace;

      if (_isSessionRecoveryError(error)) {
        final hasSession = await _ensureFirestoreSession();
        if (hasSession) {
          try {
            await _favoritesService.removeFavorite(
              userId: userId,
              productId: productId,
            );
            return;
          } catch (retryError, retryStackTrace) {
            failedError = retryError;
            failedStackTrace = retryStackTrace;
          }
        }
      }

      debugPrint(
        'Error removing favorite $productId: $failedError\n$failedStackTrace',
      );
      if (_isSessionRecoveryError(failedError)) {
        _showFavoriteError(_favoriteSessionErrorMessage());
      }
      if (_boundUserId != userId || _favoriteIds.contains(productId)) {
        return;
      }

      _favoriteIds.add(productId);
      _favoriteOrder.remove(productId);
      _favoriteOrder.insert(0, productId);
      _favoritesByKey[productId] = fallbackProduct;
      update();
    }
  }

  Future<bool> _ensureFirestoreSession() async {
    final firestoreSessionEnsurer = _firestoreSessionEnsurer;
    if (firestoreSessionEnsurer != null) {
      return firestoreSessionEnsurer();
    }

    final loginController = _loginController;
    if (loginController == null) {
      return true;
    }

    return loginController.ensureFirestoreSession();
  }

  String _favoriteSessionErrorMessage() {
    final overrideMessage = _firestoreSessionErrorProvider?.call().trim() ?? '';
    if (overrideMessage.isNotEmpty) {
      return overrideMessage;
    }

    final controllerMessage =
        _loginController?.firestoreSessionErrorMessage?.trim() ?? '';
    if (controllerMessage.isNotEmpty) {
      return controllerMessage;
    }

    return 'Unable to save favorites right now. Please try again.';
  }

  bool _isSessionRecoveryError(Object error) {
    return error is FirebaseException &&
        (error.code == 'permission-denied' || error.code == 'unauthenticated');
  }

  void _showFavoriteError(String message) {
    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) {
      return;
    }

    final favoriteErrorNotifier = _favoriteErrorNotifier;
    if (favoriteErrorNotifier != null) {
      favoriteErrorNotifier('Favorites unavailable', normalizedMessage);
      return;
    }

    AppSnackbar.show(
      title: 'Favorites unavailable',
      message: normalizedMessage,
      backgroundColor: Colors.red.shade700,
    );
  }

  String get _currentUserId => (_currentUserIdProvider?.call() ??
          _loginController?.resolvedCurrentUserId ??
          '')
      .trim();

  String _productId(ProductModel product) {
    return product.id?.trim() ?? '';
  }
}
