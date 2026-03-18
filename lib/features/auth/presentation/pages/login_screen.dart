import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _phoneController = TextEditingController();
  
  final List<Map<String, String>> _onboardingData = [
    {
      'image': 'assets/images/bike_1.png',
      'title': 'Find Your\nPerfect Bike',
    },
    {
      'image': 'assets/images/bike_2.png',
      'title': 'Chat With\nSellers',
    },
    {
      'image': 'assets/images/bike_3.png',
      'title': 'Sell Your\nBike Fast',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Carousel
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingData.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    _onboardingData[index]['image']!,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 100,
                    left: 24,
                    child: Text(
                      _onboardingData[index]['title']!,
                      style: GoogleFonts.outfit(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Page Indicator
          Positioned(
            bottom: 380,
            left: 24,
            child: SmoothPageIndicator(
              controller: _pageController,
              count: _onboardingData.length,
              effect: const ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: Colors.white,
                dotColor: Colors.white54,
              ),
            ),
          ),

          // Login Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 350,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Login Or Sign Up',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Enter phone number*',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            '+91',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.grey[300],
                        ),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: '91 1234567890',
                              hintStyle: GoogleFonts.outfit(
                                fontSize: 16,
                                color: Colors.grey[400],
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to OTP verification
                        Navigator.pushNamed(
                          context, 
                          '/otp', 
                          arguments: _phoneController.text.isNotEmpty 
                            ? '+91 ${_phoneController.text}' 
                            : '+91 1234567890', // Default for testing
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A3D6B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Get OTP',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                        children: [
                          const TextSpan(text: 'By continuing, you agree to our '),
                          TextSpan(
                            text: 'Terms of service',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          const TextSpan(text: ' & '),
                          TextSpan(
                            text: 'Privacy policy',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Logo in top left of login screen (optional, matching Figma if needed)
          Positioned(
            top: 50,
            left: 24,
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', width: 24, height: 24),
                const SizedBox(width: 8),
                Text(
                  'Bikenest',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
