import 'package:bikebooking/features/auth/presentation/bindings/auth_binding.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:bikebooking/core/theme/app_theme.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/auth/presentation/pages/otp_verification_screen.dart';
import 'features/location/presentation/pages/select_location_screen.dart';
import 'features/location/presentation/pages/location_search_screen.dart';
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
import 'features/home/presentation/pages/manage_notifications_screen.dart';
import 'features/home/presentation/pages/seller_profile_screen.dart';
import 'features/home/presentation/pages/spare_parts_detail_form_screen.dart';
import 'features/home/presentation/pages/accessories_detail_form_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bikenest',
      theme: AppTheme.lightTheme,
      initialBinding: AuthBinding(),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(builder: (context) => const SplashScreen());
        }
        if (settings.name == '/login') {
          return MaterialPageRoute(builder: (context) => const LoginScreen());
        }
        if (settings.name == '/otp') {
          final phoneNumber = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(phoneNumber: phoneNumber),
          );
        }
        if (settings.name == '/select_location') {
          return MaterialPageRoute(builder: (context) => const SelectLocationScreen());
        }
        if (settings.name == '/location_search') {
          return MaterialPageRoute(builder: (context) => const LocationSearchScreen());
        }
        if (settings.name == '/home') {
          return MaterialPageRoute(builder: (context) => const HomePage());
        }
        if (settings.name == '/select_category') {
          return MaterialPageRoute(builder: (context) => const SelectCategoryScreen());
        }
        if (settings.name == '/search') {
          return MaterialPageRoute(builder: (context) => const SearchScreen());
        }
        if (settings.name == '/filter') {
          return MaterialPageRoute(settings: settings, builder: (context) => const FilterScreen());
        }
        if (settings.name == '/filter_result') {
          return MaterialPageRoute(settings: settings, builder: (context) => const FilterResultScreen());
        }
        if (settings.name == '/bike_detail') {
          return MaterialPageRoute(builder: (context) => const BikeDetailScreen());
        }
        if (settings.name == '/chat_detail') {
          return MaterialPageRoute(builder: (context) => const ChatDetailScreen());
        }
        if (settings.name == '/messages') {
          return MaterialPageRoute(builder: (context) => const MessagesScreen());
        }
        if (settings.name == '/list_product') {
          return MaterialPageRoute(builder: (context) => const ListProductScreen());
        }
        if (settings.name == '/product_images') {
          return MaterialPageRoute(settings: settings, builder: (context) => const ProductImagesScreen());
        }
        if (settings.name == '/bike_detail_form') {
          return MaterialPageRoute(builder: (context) => const BikeDetailFormScreen());
        }
        if (settings.name == '/spare_parts_detail_form') {
          return MaterialPageRoute(builder: (context) => const SparePartsDetailFormScreen());
        }
        if (settings.name == '/accessories_detail_form') {
          return MaterialPageRoute(builder: (context) => const AccessoriesDetailFormScreen());
        }
        if (settings.name == '/bike_price_location') {
          return MaterialPageRoute(builder: (context) => const BikePriceLocationScreen());
        }
        if (settings.name == '/product_preview') {
          return MaterialPageRoute(builder: (context) => const ProductPreviewScreen());
        }
        if (settings.name == '/my_listing') {
          return MaterialPageRoute(settings: settings, builder: (context) => const MyListingScreen());
        }
        if (settings.name == '/favorites') {
          return MaterialPageRoute(builder: (context) => const FavoritesScreen());
        }
        if (settings.name == '/notifications') {
          return MaterialPageRoute(builder: (context) => const NotificationsScreen());
        }
        if (settings.name == '/profile_overview') {
          return MaterialPageRoute(builder: (context) => const ProfileOverviewScreen());
        }
        if (settings.name == '/edit_profile') {
          return MaterialPageRoute(builder: (context) => const EditProfileScreen());
        }
        if (settings.name == '/help_support') {
          return MaterialPageRoute(builder: (context) => const HelpSupportScreen());
        }
        if (settings.name == '/privacy_policy') {
          return MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen());
        }
        if (settings.name == '/manage_notifications') {
          return MaterialPageRoute(builder: (context) => const ManageNotificationsScreen());
        }
        if (settings.name == '/seller_profile') {
          return MaterialPageRoute(builder: (context) => const SellerProfileScreen());
        }
        return null;
      },
    );
  }
}
