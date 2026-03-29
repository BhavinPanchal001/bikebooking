import 'package:bikebooking/features/auth/data/services/firebase_auth_service.dart';
import 'package:bikebooking/features/auth/data/services/user_firestore_service.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:bikebooking/features/home/data/services/notification_push_service.dart';
import 'package:bikebooking/features/home/presentation/controllers/favorites_controller.dart';
import 'package:bikebooking/features/home/presentation/controllers/home_products_controller.dart';
import 'package:bikebooking/features/home/presentation/controllers/notifications_controller.dart';
import 'package:get/get.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FirebaseAuthService>(() => FirebaseAuthService(), fenix: true);
    Get.lazyPut<UserFirestoreService>(() => UserFirestoreService(),
        fenix: true);
    Get.lazyPut<LoginController>(
      () => LoginController(
        Get.find<FirebaseAuthService>(),
        Get.find<UserFirestoreService>(),
      ),
      fenix: true,
    );
    Get.lazyPut<FavoritesController>(() => FavoritesController(), fenix: true);
    Get.lazyPut<HomeProductsController>(
      () => HomeProductsController(),
      fenix: true,
    );
    Get.lazyPut<NotificationsController>(
      () => NotificationsController(),
      fenix: true,
    );
    Get.put<NotificationPushService>(
      NotificationPushService(),
      permanent: true,
    ).initialize();
  }
}

