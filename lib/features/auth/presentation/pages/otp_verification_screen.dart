import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:bikebooking/features/auth/presentation/widgets/auth_feedback_banner.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final PageController _pageController = PageController();
  final LoginController _loginController = Get.find<LoginController>();
  final List<Map<String, String>> _onboardingData = [
    {
      'image': 'assets/images/intro1.png',
      'title': 'Find Your\nPerfect Bike',
    },
    {
      'image': 'assets/images/intro22.png',
      'title': 'Chat With\nSellers',
    },
    {
      'image': 'assets/images/intro3.png',
      'title': 'Sell Your\nBike Fast',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loginController.initializeOtp(widget.phoneNumber);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Same top structure as login screen
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.primary),
                  index == 0
                      ? Positioned(
                          top: 200,
                          left: 0,
                          right: 0,
                          child: Image.asset(
                            _onboardingData[index]['image']!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 350,
                          ),
                        )
                      : index == 1
                          ? Positioned(
                              top: 200,
                              left: 0,
                              right: -100,
                              child: Image.asset(
                                _onboardingData[index]['image']!,
                                width: double.infinity,
                                height: 310,
                              ),
                            )
                          : Positioned(
                              top: 200,
                              left: 0,
                              right: -25,
                              child: Image.asset(
                                _onboardingData[index]['image']!,
                                width: double.infinity,
                                height: 280,
                              ),
                            ),
                  if (index == 0)
                    Positioned(
                      top: 180,
                      left: 0,
                      right: 0,
                      child: ClipPath(
                        clipper: TopSlantClipper(),
                        child: Container(
                          height: 100,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  if (index == 0)
                    Positioned(
                      top: 430,
                      left: 0,
                      right: 0,
                      child: ClipPath(
                        clipper: BottomSlantClipper(),
                        child: Container(
                          height: 120,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  Positioned(
                    top: 50,
                    left: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset('assets/images/logoWhite.png', width: 100, height: 70),
                        const SizedBox(height: 10),
                        Text(
                          _onboardingData[index]['title']!,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            bottom: 355,
            left: 0,
            right: 0,
            child: Center(
              child: SmoothPageIndicator(
                controller: _pageController,
                count: _onboardingData.length,
                effect: const ExpandingDotsEffect(
                  dotHeight: 4,
                  dotWidth: 8,
                  activeDotColor: Colors.white,
                  dotColor: Colors.white54,
                  spacing: 4,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GetBuilder<LoginController>(
              builder: (controller) {
                return Container(
                  height: 395,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verify your number',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                      const SizedBox(height: 16),
                      Text(
                        'Enter OTP sent to ${controller.phoneNumber ?? widget.phoneNumber}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          controller.otpControllers.length,
                          (index) => SizedBox(
                            width: 44,
                            height: 56,
                            child: TextField(
                              controller: controller.otpControllers[index],
                              focusNode: controller.otpFocusNodes[index],
                              onChanged: (value) => controller.updateOtpDigit(index, value),
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AuthFeedbackBanner(
                        errorMessage: controller.errorMessage,
                        infoMessage: controller.infoMessage,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Text(
                            "Didn't receive OTP? ",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          GestureDetector(
                            onTap: controller.isSendingOtp ? null : controller.resendOtp,
                            child: Text(
                              controller.isSendingOtp ? 'Sending...' : 'Resend OTP',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      CustomGradientButton(
                        text: controller.isVerifyingOtp ? 'Verifying...' : 'Verify',
                        onPressed: controller.isVerifyingOtp ? () {} : controller.verifyOtp,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TopSlantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height - 100);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BottomSlantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);
    path.lineTo(size.width, 100);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
