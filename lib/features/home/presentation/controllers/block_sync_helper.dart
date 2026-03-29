import 'package:bikebooking/features/chat/presentation/controllers/chat_controller.dart';
import 'package:bikebooking/features/home/presentation/controllers/favorites_controller.dart';
import 'package:bikebooking/features/home/presentation/controllers/filter_result_controller.dart';
import 'package:bikebooking/features/home/presentation/controllers/home_products_controller.dart';
import 'package:bikebooking/features/home/presentation/controllers/search_controller.dart'
    as home_search;
import 'package:bikebooking/features/home/presentation/controllers/select_category_controller.dart';
import 'package:get/get.dart';

class BlockSyncHelper {
  const BlockSyncHelper._();

  static void refreshAfterBlockChange() {
    if (Get.isRegistered<HomeProductsController>()) {
      Get.find<HomeProductsController>().loadProducts(showLoader: false);
    }
    if (Get.isRegistered<home_search.SearchController>()) {
      Get.find<home_search.SearchController>().refreshData();
    }
    if (Get.isRegistered<FilterResultController>()) {
      Get.find<FilterResultController>().refreshProducts();
    }
    if (Get.isRegistered<SelectCategoryController>()) {
      Get.find<SelectCategoryController>().refreshCategories();
    }
    if (Get.isRegistered<ChatController>()) {
      Get.find<ChatController>().reloadChats();
    }
    if (Get.isRegistered<FavoritesController>()) {
      Get.find<FavoritesController>().refreshHiddenUsers();
    }
  }
}
