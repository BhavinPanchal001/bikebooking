import 'package:bikebooking/features/auth/presentation/bindings/auth_binding.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:bikebooking/core/theme/app_theme.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/auth/presentation/pages/otp_verification_screen.dart';
import 'features/location/presentation/pages/select_location_screen.dart';
import 'features/location/presentation/pages/location_search_screen.dart';
import 'features/location/presentation/pages/change_location_screen.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/home/presentation/pages/select_category_screen.dart';
import 'features/home/presentation/pages/search_screen.dart';
import 'features/home/presentation/pages/filter_screen.dart';
import 'features/home/presentation/pages/filter_result_screen.dart';
import 'features/home/presentation/pages/bike_detail_screen.dart';
import 'features/chat/presentation/pages/chat_detail_screen.dart';
import 'features/chat/presentation/pages/messages_screen.dart';

import 'features/home/presentation/pages/list_product_screen.dart';
import 'features/home/presentation/pages/product_images_screen.dart';
import 'features/home/presentation/pages/bike_detail_form_screen.dart';
import 'features/home/presentation/pages/bike_price_location_screen.dart';
import 'features/home/presentation/pages/product_preview_screen.dart';
import 'features/home/presentation/pages/my_listing_screen.dart';
import 'features/home/presentation/pages/favorites_screen.dart';
import 'features/home/presentation/pages/notifications_screen.dart';
import 'features/home/presentation/pages/profile_overview_screen.dart';
import 'features/home/presentation/pages/edit_profile_screen.dart';
import 'features/home/presentation/pages/help_support_screen.dart';
import 'features/home/presentation/pages/privacy_policy_screen.dart';
import 'features/home/presentation/pages/terms_of_service_screen.dart';
import 'features/home/presentation/pages/manage_notifications_screen.dart';
import 'features/home/presentation/pages/seller_profile_screen.dart';
import 'features/home/presentation/pages/spare_parts_detail_form_screen.dart';
import 'features/home/presentation/pages/accessories_detail_form_screen.dart';
import 'features/home/presentation/pages/subscription_status_screen.dart';
import 'features/home/presentation/pages/blocked_users_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.black,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const SystemUiOverlayStyle _systemUiOverlayStyle =
      SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bikenest',
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        final topInset = MediaQuery.of(context).padding.top;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _systemUiOverlayStyle,
          child: Stack(
            fit: StackFit.expand,
            children: [
              child ?? const SizedBox.shrink(),
              if (topInset > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topInset,
                  child: const IgnorePointer(
                    child: ColoredBox(color: Colors.black),
                  ),
                ),
            ],
          ),
        );
      },
      initialBinding: AuthBinding(),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        MaterialPageRoute<dynamic> buildRoute(Widget child) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => child,
          );
        }

        if (settings.name == '/') {
          return buildRoute(const SplashScreen());
        }
        if (settings.name == '/login') {
          return buildRoute(const LoginScreen());
        }
        if (settings.name == '/otp') {
          final phoneNumber = settings.arguments as String;
          return buildRoute(OtpVerificationScreen(phoneNumber: phoneNumber));
        }
        if (settings.name == '/select_location') {
          return buildRoute(const SelectLocationScreen());
        }
        if (settings.name == '/location_search') {
          return buildRoute(const LocationSearchScreen());
        }
        if (settings.name == '/change_location') {
          return buildRoute(const ChangeLocationScreen());
        }
        if (settings.name == '/home') {
          return buildRoute(const HomePage());
        }
        if (settings.name == '/select_category') {
          return buildRoute(const SelectCategoryScreen());
        }
        if (settings.name == '/search') {
          return buildRoute(const SearchScreen());
        }
        if (settings.name == '/filter') {
          return buildRoute(const FilterScreen());
        }
        if (settings.name == '/filter_result') {
          return buildRoute(const FilterResultScreen());
        }
        if (settings.name == '/bike_detail') {
          return buildRoute(const BikeDetailScreen());
        }
        if (settings.name == '/chat_detail') {
          return buildRoute(const ChatDetailScreen());
        }
        if (settings.name == '/messages') {
          return buildRoute(const MessagesScreen());
        }
        if (settings.name == '/list_product') {
          return buildRoute(const ListProductScreen());
        }
        if (settings.name == '/product_images') {
          return buildRoute(const ProductImagesScreen());
        }
        if (settings.name == '/bike_detail_form') {
          return buildRoute(const BikeDetailFormScreen());
        }
        if (settings.name == '/spare_parts_detail_form') {
          return buildRoute(const SparePartsDetailFormScreen());
        }
        if (settings.name == '/accessories_detail_form') {
          return buildRoute(const AccessoriesDetailFormScreen());
        }
        if (settings.name == '/bike_price_location') {
          return buildRoute(const BikePriceLocationScreen());
        }
        if (settings.name == '/product_preview') {
          return buildRoute(const ProductPreviewScreen());
        }
        if (settings.name == '/my_listing') {
          return buildRoute(const MyListingScreen());
        }
        if (settings.name == '/favorites') {
          return buildRoute(const FavoritesScreen());
        }
        if (settings.name == '/notifications') {
          return buildRoute(const NotificationsScreen());
        }
        if (settings.name == '/profile_overview') {
          return buildRoute(const ProfileOverviewScreen());
        }
        if (settings.name == '/edit_profile') {
          return buildRoute(const EditProfileScreen());
        }
        if (settings.name == '/help_support') {
          return buildRoute(const HelpSupportScreen());
        }
        if (settings.name == '/privacy_policy') {
          return buildRoute(const PrivacyPolicyScreen());
        }
        if (settings.name == '/terms_of_service') {
          return buildRoute(const TermsOfServiceScreen());
        }
        if (settings.name == '/manage_notifications') {
          return buildRoute(const ManageNotificationsScreen());
        }
        if (settings.name == '/subscription_status') {
          return buildRoute(const SubscriptionStatusScreen());
        }
        if (settings.name == '/seller_profile') {
          return buildRoute(const SellerProfileScreen());
        }
        if (settings.name == '/blocked_users') {
          return buildRoute(const BlockedUsersScreen());
        }
        return null;
      },
    );
  }
}
