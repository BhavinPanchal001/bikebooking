import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:bikebooking/core/constants/global.dart';
import 'package:bikebooking/core/widgets/custom_button.dart';
import 'package:bikebooking/features/auth/presentation/controllers/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final PageController _pageController = PageController();

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
          // Background Carousel Area
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Primary Blue Background (Always at the bottom)
                  // Container(color: Colors.red),
                  Container(color: AppColors.primary),

                  // 2. Full-Width Background Image
                  index == 0
                      ? Positioned(
                          top:
                              200, // Lowered starting point to avoid cutting the head
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
                              top:
                                  200, // Lowered starting point to avoid cutting the head
                              left: 0,
                              right: -100,
                              child: Image.asset(
                                _onboardingData[index]['image']!,
                                // fit: BoxFit.cover,
                                width: double.infinity,
                                height: 310,
                              ),
                            )
                          : Positioned(
                              top:
                                  200, // Lowered starting point to avoid cutting the head
                              left: 0,
                              right: -25,
                              child: Image.asset(
                                _onboardingData[index]['image']!,
                                // fit: BoxFit.cover,
                                width: double.infinity,
                                height: 280,
                              ),
                            ),

                  // 3. Top Slanted "Cut" (Blue Overlay on top of image) - ONLY FOR FIRST SLIDE
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

                  // 4. Bottom Slanted "Cut" (Blue Overlay on bottom of image) - ONLY FOR FIRST SLIDE
                  if (index == 0)
                    Positioned(
                      top: 430, // Positioned at the bottom of the image segment
                      left: 0,
                      right: 0,
                      child: ClipPath(
                        clipper: BottomSlantClipper(),
                        child: Container(
                          height: 120, // Enough height to cover the transition
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                  // 5. Content (Logo + Title)
                  Positioned(
                    top: 50,
                    left: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo Row
                        Image.asset('assets/images/logoWhite.png',
                            width: 100, height: 70),
                        const SizedBox(height: 10),
                        // Main Headline
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

          // Page Indicator (Floating in the center-ish)
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

          // Login Card
          Align(
            alignment: Alignment.bottomCenter,
            child: GetBuilder<LoginController>(
              builder: (controller) {
                return Container(
                  height: 370,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Login Or Sign Up',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Color(0xFFEEEEEE), thickness: 1),
                      const SizedBox(height: 16),
                      RichText(
                        text: TextSpan(
                          text: 'Enter phone number',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                          children: const [
                            TextSpan(
                              text: '*',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 52,
                        child: Row(
                          children: [
                            Container(
                              height: 52,
                              width: 60,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xFFDDDDDD)),
                              ),
                              child: Center(
                                child: Text(
                                  '+91',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFDDDDDD)),
                                ),
                                child: TextField(
                                  controller: controller.phoneController,
                                  keyboardType: TextInputType.phone,
                                  onChanged: controller.updatePhoneNumber,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: '1234567890',
                                    hintStyle: TextStyle(color: Colors.grey),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      CustomGradientButton(
                        text: controller.isSendingOtp
                            ? 'Sending OTP...'
                            : 'Get OTP',
                        onPressed: controller.isSendingOtp
                            ? () {}
                            : controller.sendOtp,
                      ),
                      const Spacer(),
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.black45,
                            ),
                            children: [
                              const TextSpan(
                                  text: "By continuing, you agree BIENEST's "),
                              TextSpan(
                                text: 'Terms of service',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF2E4475),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const TextSpan(text: ' & '),
                              TextSpan(
                                text: 'Privacy policy',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF2E4475),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
    Path path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height - 100); // Slightly steeper slant
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
    Path path = Path();
    path.lineTo(0, 0); // Start higher on the left
    path.lineTo(size.width, 100); // Slant down to the right
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
