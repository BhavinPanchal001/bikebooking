import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/global.dart';

class AppTheme {
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.titleBody,
  );

  static const TextStyle viewAllStyle = TextStyle(
    fontFamily: 'NeueMontreal',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF262A36),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF9FBFF),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        titleLarge: sectionTitle, // mapping sectionTitle to titleLarge or similar
        labelLarge: viewAllStyle,
      ),
    );
  }
}
