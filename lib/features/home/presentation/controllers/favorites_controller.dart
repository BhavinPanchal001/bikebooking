import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/models/product_model.dart';
import 'package:bikebooking/features/home/data/services/seller_action_firestore_service.dart';
import 'package:get/get.dart';

class FavoritesController extends GetxController {
  FavoritesController({
    SellerActionFirestoreService? sellerActionService,
    LoginController? loginController,
  })  : _sellerActionService =
            sellerActionService ?? SellerActionFirestoreService(),
        _loginController = loginController ?? Get.find<LoginController>();

  final Map<String, ProductModel> _favoritesByKey = {};
  final SellerActionFirestoreService _sellerActionService;
  final LoginController _loginController;
  Set<String> _hiddenUserIds = <String>{};

  List<ProductModel> get favorites => _favoritesByKey.values
      .where((product) => !_hiddenUserIds.contains(product.sellerId.trim()))
      .toList(growable: false)
      .reversed
      .toList();

  bool get hasFavorites => favorites.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    refreshHiddenUsers();
  }

  bool isFavorite(ProductModel product) {
    return _favoritesByKey.containsKey(_favoriteKey(product));
  }

  bool toggleFavorite(ProductModel product) {
    final key = _favoriteKey(product);
    if (_favoritesByKey.containsKey(key)) {
      _favoritesByKey.remove(key);
      update();
      return false;
    }

    _favoritesByKey.remove(key);
    _favoritesByKey[key] = product;
    update();
    return true;
  }

  void removeFavorite(ProductModel product) {
    _favoritesByKey.remove(_favoriteKey(product));
    update();
  }

  void clearFavorites() {
    _favoritesByKey.clear();
    update();
  }

  Future<void> refreshHiddenUsers() async {
    final currentUserId = _loginController.resolvedCurrentUserId.trim();
    if (currentUserId.isEmpty) {
      _hiddenUserIds = <String>{};
      update();
      return;
    }

    try {
      _hiddenUserIds =
          await _sellerActionService.getHiddenUserIds(currentUserId);
    } catch (_) {
      _hiddenUserIds = <String>{};
    }
    update();
  }

  String _favoriteKey(ProductModel product) {
    final id = product.id?.trim() ?? '';
    if (id.isNotEmpty) {
      return id;
    }

    final title = product.title.trim();
    final sellerId = product.sellerId.trim();
    final createdAt = product.createdAt?.millisecondsSinceEpoch ?? 0;
    return '$sellerId|$title|$createdAt';
  }
}
