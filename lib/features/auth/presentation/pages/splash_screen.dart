import 'dart:async';
import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() {
      Get.find<LoginController>().handleSplashNavigation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo3.png',
              width: 190,
              height: 190,
            ),
          ],
        ),
      ),
    );
  }
}
