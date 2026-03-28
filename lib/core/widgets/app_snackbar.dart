import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AppSnackbar {
  static void show({
    required String title,
    required String message,
    required Color backgroundColor,
    SnackPosition snackPosition = SnackPosition.BOTTOM,
    EdgeInsets margin = const EdgeInsets.all(16),
    double borderRadius = 12,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      title,
      message,
      snackPosition: snackPosition,
      margin: margin,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      colorText: Colors.white,
      duration: duration,
      titleText: Text(
        title,
        textScaler: TextScaler.noScaling,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      messageText: Text(
        message,
        textScaler: TextScaler.noScaling,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}
