import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bikebooking/core/constants/global.dart';
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




void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bikenest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
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
          return MaterialPageRoute(builder: (context) => const FilterScreen());
        }
        if (settings.name == '/filter_result') {
          return MaterialPageRoute(builder: (context) => const FilterResultScreen());
        }
        if (settings.name == '/bike_detail') {
          return MaterialPageRoute(builder: (context) => const BikeDetailScreen());
        }
        if (settings.name == '/chat_detail') {
          return MaterialPageRoute(builder: (context) => const ChatDetailScreen());
        }
        return null;
      },
    );
  }
}
