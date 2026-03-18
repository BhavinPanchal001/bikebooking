import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/presentation/pages/splash_screen.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/auth/presentation/pages/otp_verification_screen.dart';
import 'features/location/presentation/pages/select_location_screen.dart';
import 'features/location/presentation/pages/location_search_screen.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A3D6B)),
        useMaterial3: true,
        textTheme: GoogleFonts.outfitTextTheme(),
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
        return null;
      },
    );
  }
}
